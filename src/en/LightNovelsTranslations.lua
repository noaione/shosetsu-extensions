-- {"id":26375,"ver":"0.2.0","libVer":"1.0.0","author":"N4O""dep":["WPCommon>=1.0.0"]}

local baseURL = "https://lightnovelstranslations.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-lightnovelstranslations.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param elem Element
local function cleanupPassages(elem)
	local isRemoved = WPCommon.cleanupElement(elem)
	if isRemoved then return end
    local style = elem:attr("style")
    local className = elem:attr("class")
    local isAlignCenter = style and style:find("text-align", 0, true) and style:find("center", 0, true) and true or false
    local isValidTocData = isAlignCenter and WPCommon.isTocRelated(elem:text()) and true or false
    if isValidTocData then
        elem:remove()
    end
    -- ads
    if className and className:find("code-block", 0, true) then
        elem:remove()
    end
    if elem:id():find("atatags", 0, true) then
        elem:remove()
    end
end

local function parsePassage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("div#content"):selectFirst("div")
    local p = content:selectFirst(".entry-content")

    -- remove chapter nav
    map(content:select("div#textbox"), function (v) v:remove() end)

	map(p:select("p"), cleanupPassages)
    map(p:select("div"), cleanupPassages)

	-- add title
	local chTitle = content:selectFirst(".entry-title")
	if chTitle then
		local title = chTitle:text()
		p:child(0):before("<h2>" .. title .. "</h2>")
	end

    return p
end

local function parseListings(data)
    local doc = GETDocument(baseURL)
    local activeNovels = flatten(mapNotNil(doc:selectFirst("ul#prime_nav"):children(), function(v)
        local text = v:selectFirst("a"):text()
        -- #prime_nav > li (this) > ul.sub-menu > li > ul.sub-menu > li > a
        -- ignore any sub-link that contains "Novel Illustrations"
        return text:find("Active Novels", 0, true) and nil or map(v:select("ul.sub-menu > li > ul.sub-menu > li > a"), function (v)
            -- ignore any sub-link that contains "Novel Illustrations"
            if v:text():find("Novel Illustrations", 0, true) then return nil end
            return Novel {
                title = v:text(),
                link = shrinkURL(v:attr("href"))
            }
        end)
    end))
    local otherNovels = flatten(mapNotNil(doc:selectFirst("ul#prime_nav"):children(), function(v)
        local text = v:selectFirst("a"):text()
        -- #prime_nav > li (this) > ul.sub-menu > li > a
        -- do not include Active Novels, but match "Novels"
        local isActive = text:find("Active Novels", 0, true) and true or false
        if isActive then return nil end
        return text:find("Novels", 0, true) and map(v:select("ul.sub-menu > li > a"), function (vv)
            -- ignore any sub-link that contains "Novel Illustrations"
            if vv:text():find("Novel Illustrations", 0, true) then return nil end
            return Novel {
                title = vv:text(),
                link = shrinkURL(vv:attr("href"))
            }
        end) or nil
    end))
    -- merge the two tables
    local novels = {}
    for _, v in ipairs(activeNovels) do
        table.insert(novels, v)
    end
    for _, v in ipairs(otherNovels) do
        table.insert(novels, v)
    end
	-- sort result
	-- table.sort(novels, function (a, b) return a and a.title < b and b.title end)
    return novels
end

--- @param entryContent Element
--- @return ArrayList
local function parseChaptersListing(entryContent)
    -- chapters are put into an accordion
    -- div.su-accordion > div.su-spoiler > div.su-spoiler-content > p a
    local chapters = mapNotNil(entryContent:selectFirst("div.su-accordion"):select("div.su-spoiler"), function (v)
        local title = v:selectFirst("div.su-spoiler-title"):text()
        local content = v:selectFirst("div.su-spoiler-content")
        return map(content:select("a"), function (vv)
            return NovelChapter {
                title = title .. " - " .. vv:text(),
                link = shrinkURL(vv:attr("href"))
            }
        end)
    end)
    return AsList(flatten(chapters))
end

--- @param url string
--- @return string
local function cleanImgUrl(url)
	local found = url:find("?resize=")
    if found == nil then return url end
	return url:sub(0, found - 1)
end

return {
	id = 26375,
	name = "Light Novels Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/LightNovelsTranslations.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, parseListings)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePassage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local entry = doc:selectFirst("div#content"):selectFirst("div")

		local info = NovelInfo {
			title = entry:selectFirst(".entry-title"):text(),
		}
        local content = entry:selectFirst(".entry-content")

		local imageTarget = content:selectFirst("img")
		if imageTarget then
			info:setImageURL(cleanImgUrl(imageTarget:attr("src")))
		end

		if loadChapters then
			info:setChapters(parseChaptersListing(content))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
