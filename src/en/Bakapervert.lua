-- {"id":1331219,"ver":"1.2.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://bakapervert.wordpress.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-bakapervert%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param doc Document
local function propagateToDocument(doc)
	local content = doc:selectFirst(".entry-content")

	local links = mapNotNil(content:select("a"), function(link)
		local href = link:attr("href")
		return href and href:match("^https?://bakapervert%.wordpress%.com") and href
	end)

	if links == nil then
		local firstLink = content:selectFirst("a")
		return GETDocument(expandURL(shrinkURL(firstLink:attr("href"))))
	end

	local fisrtLink = links[1]
	return GETDocument(expandURL(shrinkURL(fisrtLink)))
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#content div")
    local p = content:selectFirst(".entry-content")

	-- check if p is null
	if p == nil then
		doc = propagateToDocument(doc)
		content = doc:selectFirst("#content div")
		p = content:selectFirst(".entry-content")
	end

	WPCommon.cleanupElement(p)

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    -- get last "p" to remove prev/next links
    local allElements = p:select("p")
	WPCommon.cleanupPassages(allElements, false)

    return p
end

return {
	id = 1331219,
	name = "bakapervert",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Bakapervert.jpg",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("div#access ul"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Projects", 0, true)) and
						map(v:selectFirst("ul.sub-menu"):select("> li > a"), function(v) return v end)
			end)), function(v)
				return Novel {
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local content = doc:selectFirst("#content div")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title"):text(),
		}

		local imageTarget = content:selectFirst("img")
		if imageTarget then
			info:setImageURL(imageTarget:attr("src"))
		end

		if loadChapters then
			info:setChapters(AsList(mapNotNil(content:selectFirst(".entry-content"):select("p a"), function (v, i)
				local chUrl = v:attr("href")
				return (chUrl:find("bakapervert.wordpress.com", 0, true)) and
					NovelChapter {
						order = i,
						title = v:text(),
						link = shrinkURL(chUrl)
					}
			end)))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
