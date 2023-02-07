-- {"id":22933,"ver":"0.1.0","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://www.ainushi.com"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-www%.ainushi%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param str string
--- @param pattern string
local function contains(str, pattern)
	return str:find(pattern, 0, true) and true or false
end

--- @param testString string
--- @return boolean
local function isTocRelated(testString)
	local lowerTestStr = testString:lower()

	-- check "ToC"
	if lowerTestStr:find("toc", 0, true) then
		return true
	end
	if lowerTestStr:find("table of content", 0, true) then
		return true
	end
	if lowerTestStr:find("table of contents", 0, true) then
		return true
	end
	if lowerTestStr:find("main page", 0, true) then
		return true
	end

	-- check "Previous"
	if lowerTestStr:find("previous", 0, true) then
		return true
	end

	-- check "Next"
	if lowerTestStr:find("Next", 0, true) then
		return true
	end
	if lowerTestStr:find("next", 0, true) then
		return true
	end
	return false
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
	local article = doc:selectFirst("article")
	local content = article:selectFirst(".post-wrap > .entry-content")

	map(content:children(), function (v)
		local className = v:attr("class")
		if className:find("patreon_button") then
			v:remove()
		end
		if className:find("sharedaddy") then
			v:remove()
		end
		if className:find("wp-post-navigation", 0, true) and true or false then
			v:remove()
		end
		if className:find("wpulike", 0, true) and true or false then
			v:remove()
		end
		local style = v:attr("style")
		local isAlignCenter = style and style:find("text-align", 0, true) and style:find("center", 0, true) and true or false
		local isValidTocData = isTocRelated(v:text()) and isAlignCenter and true or false
		if isValidTocData then
			v:remove()
		end
	end)

	-- add title
	local postTitle = article:selectFirst(".post-header > .entry-title")
	if postTitle then
		local title = postTitle:text()
		content:child(0):before("<h2>" .. title .. "</h2><hr/>")
	end

    return content
end

--- @param doc Document
local function parseListings(doc)
	local navigation = doc:selectFirst("ul#et-secondary-menu")

	return mapNotNil(navigation:select("li a"), function (v)
		return Novel {
			title = v:text(),
			link = shrinkURL(v:attr("href"))
		}
	end)
end


--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, loadChapters)
	local postBody = doc:selectFirst("article > .post-wrap")
	local postTitle = postBody:selectFirst(".entry-title"):text()
	local content = postBody:selectFirst(".entry-content")

	local info = NovelInfo {
		title = postTitle,
	}

	local imageTarget = content:selectFirst("img")
	if imageTarget then
		info:setImageURL(imageTarget:attr("src"))
	end

	if loadChapters then
		local chapters = {}
		mapNotNil(content:select("p a"), function (v)
			local url = v:attr("href")
			if not contains(url, "www.ainushi.com") then
				return nil
			end
			local _temp = NovelChapter {
				order = #chapters + 1,
				title = v:text(),
				link = shrinkURL(url)
			}
			chapters[#chapters + 1] = _temp
		end)
		info:setChapters(AsList(chapters))
	end
	return info
end

return {
	id = 22933,
	name = "Ainushi Translation",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Ainushi.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function ()
			return parseListings(GETDocument("https://www.ainushi.com/"))
		end),
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		return parseNovelInfo(doc, loadChapters)
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
