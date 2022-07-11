-- {"id":309841,"ver":"0.1.1","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://kurokurori.wordpress.com"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-kurokurori%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param testString string
--- @return boolean
local function isTocRelated(testString)
	-- check "ToC"
	if testString:find("ToC", 0, true) then
		return true
	end
	if testString:find("toc", 0, true) then
		return true
	end
	if testString:find("table of content", 0, true) then
		return true
	end
	if testString:find("table of contents", 0, true) then
		return true
	end
	if testString:find("Table of content", 0, true) then
		return true
	end
	if testString:find("Table of contents", 0, true) then
		return true
	end
	if testString:find("Table of Content", 0, true) then
		return true
	end
	if testString:find("Table of Contents", 0, true) then
		return true
	end

	-- check "Previous"
	if testString:find("Previous", 0, true) then
		return true
	end
	if testString:find("previous", 0, true) then
		return true
	end

	-- check "Next"
	if testString:find("Next", 0, true) then
		return true
	end
	if testString:find("next", 0, true) then
		return true
	end
	return false
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#main article")
    local p = content:selectFirst(".entry-content")

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    local allElements = p:select("p")
	map(allElements, function (v)
		if isTocRelated(v:text()) then
			v:remove()
		end
	end)

    return p
end

return {
	id = 309841,
	name = "Kuro Kurori's Lounge",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/KuroKurori.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("ul#primary-menu"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Our Girls", 0, true)) and
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
		local content = doc:selectFirst("#main > article")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title"):text(),
		}		

		local imageTarget = content:selectFirst("img")
		if imageTarget then
			info:setImageURL(imageTarget:attr("src"))
		end

		if loadChapters then
			local mainContents = content:select("div.entry-content > div.entry-content")
			local lastContent = mainContents:get(mainContents:size() - 1)
			info:setChapters(AsList(mapNotNil(lastContent:select("p a"), function (v, i)
				local chUrl = v:attr("href")
				return (chUrl:find("kurokurori.wordpress.com", 0, true)) and
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
