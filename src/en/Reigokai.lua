-- {"id":221702,"ver":"0.1.0","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://www.isekailunatic.com"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-www%.isekailunatic%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param testString string
--- @return boolean
local function isTocRelated(testString)
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
	return false
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("article")
    local p = content:selectFirst(".entry-content")

	local dark_switch = p:selectFirst("div.wp-dark-mode-switcher")
	if dark_switch then dark_switch:remove() end
	
    -- get last "p" to remove prev/next links
    local allElements = p:select("p")
    local lastElement = allElements:get(allElements:size() - 1)
	if lastElement:select("> a"):size() > 0 then
		lastElement:remove()
	end

	map(p:children(), function (v)
		local className = v:attr("class")
		if className:find("patreon_button") then
			v:remove()
		elseif className:find("sharedaddy") then
			v:remove()
		end
	end)

    return p
end

--- @param url string
--- @return string
local function cleanImgUrl(url)
	local found = url:find("?w=")
	if (found == nil) then
	    return url
	end
	return url:sub(0, found - 1)
end

--- @param doc Document
--- @return string
local function findNovelTitle(doc)
	local articles = doc:selectFirst("article")
	if articles then
		local title = articles:selectFirst(".entry-title")
		if title then
			return title:text()
		else
			local bgeEntryContent = articles:selectFirst(".bge-entry-content")
			if bgeEntryContent then
				local cTitle = bgeEntryContent:selectFirst("h4")
				return cTitle:text()
			else
				local entryContent = articles:selectFirst(".entry-content")
				local cTitle = entryContent:selectFirst("h2")
				return cTitle:text()
			end
		end
	end
	-- get from header
	local titleHead = doc:selectFirst("title")
	if titleHead then
		local actualTitle = titleHead:text()
		-- remove `| Reigokai: Isekai TL` from title
		return actualTitle:gsub("| Reigokai: Isekai TL", "")
	end
	return "Unknown title"
end

return {
	id = 221702,
	name = "Reigokai - Isekai Lunatic",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Reigokai.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("ul#primary-menu"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Active Project", 0, true) or text == "Novels") and
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
		local articles = doc:selectFirst("article")

		local info = NovelInfo {
			title = findNovelTitle(doc),
		}

		local imageTarget = articles:selectFirst("img")
		if imageTarget then
			info:setImageURL(cleanImgUrl(imageTarget:attr("src")))
		end

		if loadChapters then
			info:setChapters(AsList(mapNotNil(articles:selectFirst("div"):select("p a"), function (v, i)
				local chUrl = v:attr("href")
				return (chUrl:find("www.isekailunatic.com", 0, true) and v:children():size() < 1) and
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
