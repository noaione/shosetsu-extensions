-- {"ver":"1.0.0","author":"N4O","dep":["WPCommon"]}

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
    
    local wpOpt = "i%d%.wp%.com"
    local wpOptRegex = "https?://" .. wpOpt .. "/(.+)%?.+"
    url = url:gsub(wpOptRegex, "https://%1")
    return url
end

local defaults = {
	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML,

    --- @type function|nil
    stripMechanics = nil,
}

function defaults:expandURL(url)
    if startsWith(url, "/") then
        return self.baseURL .. url
    end
    return self.baseURL .. "/" .. url
end

function defaults:shrinkURL(url)
	return url:gsub("https?://.-/", "")
end

--- @param doc Document
--- @return Novel[]
function defaults:parseListing(doc)
    local listUpdates = doc:selectFirst(".listupd")

    local _novels = {}
    map(listUpdates:select("> article"), function (article)
        local linkTarget = article:selectFirst("a")
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
            local imgUrl = imageEl:attr("src")
            if not startsWith(imgUrl, "data:image") then
                novel:setImageURL(stripWPOptimizer(imgUrl))
            end
        end
        _novels[#_novels + 1] = novel
    end)
    return _novels
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
    local imgThumb = sectionHead:selectFirst(".thumbook"):selectFirst("img"):attr("src")

    if startsWith(imgThumb, "data:image") then
        imgThumb = nil
    end

    local novel = NovelInfo {
        title = title,
    }

    if imgThumb then
        novel:setImageURL(stripWPOptimizer(imgThumb))
    end

    local genreMap = infoX:selectFirst(".genxed")
    novel:setGenres(map(genreMap:children(), function (genre)
        return genre:text()
    end))

    local infoPills = infoX:selectFirst(".spe")
    local _authors = {}
    local _artists = {}
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
            print(status, data, novelUrl)
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
    local query = data[QUERY]
    local page = data[PAGE]

    local reqUrl = "/page/" .. page .. "/?s=" .. query
    local doc = GETDocument(self.expandURL(reqUrl))
    return self.parseListing(doc)
end

--- @param data table
--- @return Novel[]
function defaults:latestNovel(data)
    local page = data[PAGE]

    local reqUrl = "/series/?page=" .. page .. "&status=&type=&order=update"
    local doc = GETDocument(self.expandURL(reqUrl))
    return self.parseListing(doc)
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

	return _self
end
