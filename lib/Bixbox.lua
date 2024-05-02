-- {"ver":"1.1.1","author":"N4O","dep":["WPCommon"]}

local encode = Require("url").encode
local WPCommon = Require("WPCommon");

local cssExtras = [[
.epheader {
    text-align: center;
}
.epsubtitle {
    text-align: center;
}
]]

local function startsWith(data, start)
    return data:sub(1, #start) == start
end

--- @param url string|nil
--- @return string|nil
local function stripWPOptimizer(url)
    -- remove wordpress image optimizer
    -- ex: https://i2.wp.com/knoxt.space/wp-content/uploads/2023/06/I-Just-Want-To-Retire-Quietly.jpeg?resize=370,500
    -- into: https://knoxt.space/wp-content/uploads/2023/06/I-Just-Want-To-Retire-Quietly.jpeg

    if url == nil then
        return nil
    end

    local wpOpt = "i%d%.wp%.com"
    local wpOptRegex = "https?://" .. wpOpt .. "/(.+)%?.+"
    url = url:gsub(wpOptRegex, "https://%1")
    return url
end

--- @param url string|nil
--- @return string|nil
local function stripEzoicOptimizer(url)
    -- remove ezoicdn image optimizer
    -- ex: https://sf.ezoiccdn.com/ezoimgfmt/i1.wp.com/awebstories.com/wp-content/uploads/2023/09/Rockwalled-Lou.jpg?resize=151,215
    -- into: https://i1.wp.com/awebstories.com/wp-content/uploads/2023/09/Rockwalled-Lou.jpg?resize=151,215
    -- if there's still wp optimizer, we can call stripWPOptimizer later

    if url == nil then
        return nil
    end

    local ezoicOpt = "%s%.ezoiccdn%.com/ezoimgfmt/"
    local ezoicOptRegex = "https?://" .. ezoicOpt .. "/(.+)%?.+"
    url = url:gsub(ezoicOptRegex, "https://%1")
    return stripWPOptimizer(url)
end

--- Getting genres/types
--- function getAllNameForInput(htmlQuery) {
---   const queries = document.querySelectorAll(htmlQuery);
---   const mappedData = [];
---   queries.forEach((query) => mappedData.push(query.nextElementSibling.textContent));
--- 	return mappedData;
--- }
--- getAllNameForInput("input[name='genre[]']")
local settings = {}

local defaults = {
	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML,

    --- @type function|nil
    stripMechanics = nil,

    --- @type table|nil
    availableGenres = nil,
    availableTypes = nil,
}

local ORDER_BY_FILTER_EXT = { "A-Z", "Z-A", "Latest Added", "Latest Update", "Popular" }
local ORDER_BY_FILTER_KEY = 2
local STATUS_FILTER_KEY_COMPLETED = 6
local STATUS_FILTER_KEY_ONGOING = 7
local STATUS_FILTER_KEY_ON_HOLD = 8

function defaults:expandURL(url)
    if startsWith(url, "/") then
        return self.baseURL .. url
    end
    return self.baseURL .. "/" .. url
end

function defaults:shrinkURL(url)
	return url:gsub("https?://.-/", "")
end

function defaults:createSearchString(tbl)
    local query = tbl[QUERY]
    local page = tbl[PAGE]
    local orderBy = tbl[ORDER_BY_FILTER_KEY]

    local url = "/page/" .. page .. "/?s=" .. query .. "&expand_article=1"

    if orderBy ~= nil then
        url = url .. "&order=" .. ({
            [0] = "title",
            [1] = "titlereverse",
            [2] = "latest",
            [3] = "update",
            [4] = "popular"
        })[orderBy]
    end
    if tbl[STATUS_FILTER_KEY_COMPLETED] then
        url = url .. "&status=completed"
    end
    if tbl[STATUS_FILTER_KEY_ONGOING] then
        url = url .. "&status=ongoing"
    end
    if tbl[STATUS_FILTER_KEY_ON_HOLD] then
        url = url .. "&status=hiatus"
    end

    for key, value in pairs(self.genres_map) do
        if tbl[key] then
            url = url .. "&genre[]=" .. encode(value)
        end
    end

    for key, value in pairs(self.types_map) do
        if tbl[key] then
            url = url .. "&type[]=" .. encode(value)
        end
    end

    return self.appendToSearchURL(url, tbl)
end

---@param str string
---@param tbl table
---@return string
function defaults:appendToSearchURL(str, tbl)
	return str
end

---@param tbl table
---@return table
function defaults:appendToSearchFilters(tbl)
	return tbl
end

--- @param imgEl Element
--- @return string|nil
local function getImgSrc(imgEl)
    local ezoiccdn = imgEl:attr("data-ezsrc")
    if ezoiccdn ~= "" then
        return stripEzoicOptimizer(ezoiccdn)
    end

	-- Check data-srcset:
	local srcset = imgEl:attr("data-srcset")
	if srcset ~= "" then
		-- Get the largest image.
		local max_size, max_url = 0, ""
		for url, size in srcset:gmatch("(http.-) (%d+)w") do
			if tonumber(size) > max_size then
				max_size = tonumber(size)
				max_url = url
			end
		end
		return max_url
	end

	-- Check data-src:
	srcset = imgEl:attr("data-src")
	if srcset ~= "" then
		return srcset
	end

	-- Check data-lazy-src:
	srcset = imgEl:attr("data-lazy-src")
	if srcset ~= "" then
		return srcset
	end

    return imgEl:attr("src")
end

function defaults:parseCompactListing(article)
    local linkTarget = article:selectFirst("> a")
    local title = (linkTarget:selectFirst(".ntitle") or linkTarget):text()
    local link = self.shrinkURL(linkTarget:attr("href"))
    local imageEl = linkTarget:selectFirst("img")
    if imageEl == nil then
        imageEl = article:selectFirst(".mdthumb"):selectFirst("img")
    end

    local novel = Novel {
        title = title,
        link = link,
    }
    if imageEl then
        local imgUrl = getImgSrc(imageEl)
        -- check not nill and not data:image
        if imgUrl and not startsWith(imgUrl, "data:image") then
            novel:setImageURL(stripEzoicOptimizer(imgUrl))
        end
    end

    return novel
end

function defaults:parsePrettyListing(article)
    local divTarget = article:selectFirst("> div")

    local headline = article:selectFirst("h2")
    local linkTarget = headline:selectFirst("a")

    local fallbackFromLink = linkTarget:attr("oldtitle") or linkTarget:attr("title") or linkTarget:text()
    local title = headline and headline:text() or fallbackFromLink

    local novel = Novel {
        title = title,
        link = self.shrinkURL(linkTarget:attr("href")),
    }

    local imgEl = divTarget:selectFirst("img") or divTarget:selectFirst(".wp-post-image")
    if imgEl then
        local imgUrl = getImgSrc(imgEl)
        if imgUrl and not startsWith(imgUrl, "data:image") then
            novel:setImageURL(stripEzoicOptimizer(imgUrl))
        end
    end

    return novel
end

--- @param doc Document
--- @return Novel[]
function defaults:parseListing(doc)
    local listUpdates = doc:selectFirst(".listupd")

    local _fetchNovels = {}
    map(listUpdates:select("> article"), function (article)
        local mainDiv = article:selectFirst("> div")
        if mainDiv:selectFirst("> div") then
            local novel = self.parsePrettyListing(mainDiv)
            _fetchNovels[#_fetchNovels + 1] = novel
        else
            local novel = self.parseCompactListing(mainDiv)
            _fetchNovels[#_fetchNovels + 1] = novel
        end
    end)
    return _fetchNovels
end


--- @param data table
--- @param loadChapters boolean
--- @return NovelInfo
function defaults:parseNovel(novelUrl, loadChapters)
    local doc = GETDocument(self.expandURL(novelUrl))

    local postBody = doc:selectFirst(".postbody")

    local sectionHead = postBody:selectFirst(".animefull")
    local infoX = sectionHead:selectFirst(".infox")

    local title = infoX:selectFirst(".entry-title"):text()
    local imgThumb = getImgSrc(sectionHead:selectFirst(".thumbook"):selectFirst("img"))

    if startsWith(imgThumb, "data:image") then
        imgThumb = nil
    end

    local novel = NovelInfo {
        title = title,
    }

    if imgThumb then
        novel:setImageURL(stripEzoicOptimizer(imgThumb))
    end

    local genreMap = infoX:selectFirst(".genxed")
    if genreMap then
        novel:setGenres(map(genreMap:children(), function (genre)
            return genre:text()
        end))
    end

    local infoPills = infoX:selectFirst(".spe")
    local _authors = {}
    local _artists = {}
    -- Doing it like this to handle incosistency because hahahahhahahaha
    map(infoPills:children(), function (info)
        local pre = (info:selectFirst("b") or info:selectFirst("strong")):text()
        local data = info:text():gsub("^" .. pre, "")
        -- strip trailing and leading spaces
        data = data:gsub("^%s*(.-)%s*$", "%1")
        if WPCommon.contains(pre, "Author") then
            _authors[#_authors + 1] = data
        elseif WPCommon.contains(pre, "Artist") then
            _artists[#_artists + 1] = data
        elseif WPCommon.contains(pre, "Status") then
            local status = ({
                ["Hiatus"] = NovelStatus.PAUSED,
                ["Ongoing"] = NovelStatus.PUBLISHING,
                ["Completed"] = NovelStatus.COMPLETED,
            })[data]
            if status ~= nil then
                novel:setStatus(status)
            end
        end
    end)

    if #_authors > 0 then
        novel:setAuthors(_authors)
    end
    if #_artists > 0 then
        novel:setArtists(_artists)
    end

    local synopsisArea = postBody:selectFirst(".synp")
    if synopsisArea then
        local synopsisText = ""
        map(synopsisArea:selectFirst(".entry-content"):select("p"), function (p)
            synopsisText = synopsisText .. p:text():gsub("<br>", "\n") .. "\n"
        end)
        -- strip last \n
        synopsisText = synopsisText:gsub("\n$", "")
        novel:setDescription(synopsisText)
    end

    if loadChapters then
        -- load chapters
        local chapterList = doc:selectFirst(".eplisterfull")

        --- @type NovelChapter[]
        local _loadedChapters = {}
        map(chapterList:select("> ul > li"), function (vv)
            local linkData = vv:selectFirst("a")
            local order = tonumber(vv:attr("data-id"))

            local epNum = linkData:selectFirst(".epl-num"):text()
            local epTitle = linkData:selectFirst(".epl-title"):text()
            local published = linkData:selectFirst(".epl-date")

            local aLink = linkData:attr("href")
            local chNov = NovelChapter {
                title = epNum .. " — " .. epTitle,
                link = self.shrinkURL(aLink),
                order = order
            }
            if published then
                chNov:setRelease(published:text())
            end
            _loadedChapters[#_loadedChapters + 1] = chNov
        end)

        novel:setChapters(AsList(_loadedChapters))
    end
    return novel
end

--- @param chapterUrl string
--- @return any
function defaults:getPassage(chapterUrl)
    local doc = GETDocument(self.expandURL(chapterUrl))

    local section = doc:selectFirst(".epwrapper")

    local chapterContainer = section:selectFirst(".epcontent")

    if self.stripMechanics then
        self.stripMechanics(chapterContainer)
    end

    local entryTitle = section:selectFirst(".entry-title")
    local entrySubtitle = section:selectFirst(".entry-subtitle")
    local hrExtra = "<hr/>"
    if entrySubtitle then
        chapterContainer:child(0):before("<h3 class=\"epsubtitle\">" .. entrySubtitle:text() .. "</h3><hr/>")
        hrExtra = ""
    end
    chapterContainer:child(0):before("<h2 class=\"epheader\">" .. entryTitle:text() .. "</h2>" .. hrExtra)

    return pageOfElem(chapterContainer, false, cssExtras)
end

--- @param data table
--- @return Novel[]
function defaults:search(data)
    -- &expand_article=1 => Awebstories
    local reqUrl = self.createSearchString(data)
    local doc = GETDocument(self.expandURL(reqUrl))
    return self.parseListing(doc)
end

--- @param data table
--- @return Novel[]
function defaults:latestNovel(data)
    local page = data[PAGE]

    -- &expand_article=1 => Awebstories
    local reqUrl = "/series/?page=" .. page .. "&status=&type=&order=update&expand_article=1"
    local doc = GETDocument(self.expandURL(reqUrl))
    return self.parseListing(doc)
end

--- @param genreKey string
local function fixupGenre(genreKey)
    -- remove ( and ), space change to -, lowercase it
    return genreKey:lower():gsub(" ", "-"):gsub("%(", ""):gsub("%)", "")
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })

    _self["isSearchIncrementing"] = true
    _self["baseURL"] = baseURL
    _self["listings"] = {
        Listing("Latest", true, _self.latestNovel),
    }
    _self["startIndex"] = 1

    _self.genres_map = {}
    _self.types_map = {}
    local keyIDGenre = 100
    local keyIDType = 300
    local filters = {
        DropdownFilter(ORDER_BY_FILTER_KEY, "Order by", ORDER_BY_FILTER_EXT),
        FilterGroup("Status", {
            CheckboxFilter(STATUS_FILTER_KEY_ONGOING, "Ongoing"),
            CheckboxFilter(STATUS_FILTER_KEY_ON_HOLD, "Hiatus"),
            CheckboxFilter(STATUS_FILTER_KEY_COMPLETED, "Completed")
        }),
    }

    if _self.availableGenres ~= nil then
        filters[#filters + 1] = FilterGroup("Genres", map(_self.availableGenres, function (v)
            keyIDGenre = keyIDGenre + 1
            _self.genres_map[keyIDGenre] = fixupGenre(v)
            return CheckboxFilter(keyIDGenre, v)
        end))
    end
    if _self.availableTypes ~= nil then
        filters[#filters + 1] = FilterGroup("Type", map(_self.availableTypes, function (v)
            keyIDType = keyIDType + 1
            _self.types_map[keyIDType] = fixupGenre(v)
            return CheckboxFilter(keyIDType, v)
        end))
    end

    filters = _self.appendToSearchFilters(filters)
    _self["searchFilters"] = filters
	_self["updateSetting"] = function(id, value)
		settings[id] = value
	end

	return _self
end
