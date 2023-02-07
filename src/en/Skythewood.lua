-- {"id":22903,"ver":"0.1.1","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://skythewood.blogspot.com"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-skythewood%.blogspot%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
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
	local postBody = doc:selectFirst("div#main > div > .blog-posts > .date-outer > .date-posts > .post-outer > .post")
	local content = postBody:selectFirst(".post-body")

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
		local isValidTocData = isTocRelated(v:text()) and true or false
		if isValidTocData then
			v:remove()
		end
	end)

	-- add title
	local postTitle = postBody:selectFirst(".post-title")
	if postTitle then
		local title = postTitle:text()
		content:child(0):before("<h2>" .. title .. "</h2><hr/>")
	end

    return content
end

--- @param elem Element|nil
--- @return Element|nil
local function findSeparatorNode(elem)
	if not elem then
		return nil
	end
	local previous = elem:previousElementSibling()
	if previous then
		local className = previous:attr("class")
		-- if yes, then return the previous node
		-- if no, call this function again
		if className:find("separator", 0, true) then
			return previous
		else
			return findSeparatorNode(previous)
		end
	end
	return nil
end

--- @param str string
--- @param pattern string
local function contains(str, pattern)
	return str:find(pattern, 0, true) and true or false
end

--- @param doc Document
local function parseListings(doc)
	local postBody = doc:selectFirst("div#main > div > .blog-posts > .date-outer > .date-posts > .post-outer > .post")
	local content = postBody:selectFirst(".post-body")

	local listings = {}
	local _addedUrl = {} -- deduplication
	mapNotNil(content:select("a"), function (v)
		local url = v:attr("href")
		if not contains(url, "skythewood.blogspot") then
			return nil
		end
		-- skythewood.blogspot.sg need to be fixed to skythewood.blogspot.com
		url = url:gsub("skythewood%.blogspot%.sg", "skythewood.blogspot.com")
		local text = v:text()
		if contains(text:lower(), "click here for") then
			return nil
		end

		if _addedUrl[url] then
			return nil
		end

		if text:len() < 1 then
			return nil
		end

		_addedUrl[url] = true
		local _temp = Novel {
			title = v:text(),
			link = shrinkURL(url)
		}
		local _parent = v:parent()
		local topNode = findSeparatorNode(_parent)

		if topNode then
			local imgNode = topNode:selectFirst("img")
			if imgNode then
				_temp:setImageURL(imgNode:attr("src"))
			end
		end
		listings[#listings + 1] = _temp
	end)
	return listings
end

--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, loadChapters)
	local postBody = doc:selectFirst("div#main > div > .blog-posts > .date-outer > .date-posts > .post-outer > .post")
	local content = postBody:selectFirst(".post-body")
	local postTitle = postBody:selectFirst(".post-title"):text()

	local info = NovelInfo {
		title = postTitle,
	}

	local imageTarget = content:selectFirst("img")
	if imageTarget then
		info:setImageURL(imageTarget:attr("src"))
	end

	if loadChapters then
		local chapters = {}
		mapNotNil(content:select("a"), function (v)
			local url = v:attr("href")
			if not contains(url, "skythewood.blogspot.com") then
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
	id = 22903,
	name = "Skythewood",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Skythewood.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Ongoing", false, function ()
			return parseListings(GETDocument("https://skythewood.blogspot.com/p/projects.html"))
		end),
		Listing("Completed/Dropped", false, function ()
			return parseListings(GETDocument("https://skythewood.blogspot.com/p/done.html"))
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
