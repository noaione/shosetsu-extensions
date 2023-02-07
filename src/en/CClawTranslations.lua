-- {"id":24903,"ver":"0.1.1","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://cclawtranslations.home.blog"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-cclawtranslations%.home%.blog", "")
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

--- @param text string
--- @return boolean
local function isAdsText(text)
	local lowerText = text:lower()
	if contains("twitter:") then
		return true
	end
	if contains("facebook:") then
		return true
	end
	if contains("discord server:") then
		return true
	end
	if contains("discord.gg") then
		return true
	end
	if contains("patreon.com") then
		return true
	end
	if contains("UCOQyW7GmCyTKwjCJEaTBWRw") then
		return true
	end
	return false
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
	local postBody = doc:selectFirst("article")
	local content = postBody:selectFirst(".entry-content")

	local jpFlair = content:selectFirst("#jp-post-flair")
	if jpFlair then jpFlair:remove() end

	map(content:children(), function (v)
		local className = v:attr("class")
		if contains(className, "sharedaddy") then
			v:remove()
			return
		end
		local idTag = v:attr("id")
		if contains(idTag, "atatags") then
			v:remove()
			return
		end
		local style = v:attr("style")
		local isAlignCenter = style and style:find("text-align", 0, true) and style:find("center", 0, true) and true or false
		local isValidTocData = isTocRelated(v:text()) and isAlignCenter and true or false
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
local function findImageNode(elem)
	if not elem then
		return nil
	end

	local nextSib = elem:nextElementSibling()
	if nextSib then
		local className = nextSib:attr("class")
		if contains(className, "wp-block-image") then
			local imgNode = nextSib:selectFirst("img")
			if imgNode then
				return imgNode
			end
		end
		local tagName = nextSib:tagName()
		if tagName == "h2" and contains(className, "wp-block-heading") then
			-- we reach the next heading, stop!
			return nil
		end
		return findImageNode(nextSib)
	end
	return nil
end

--- @param doc Document
local function parseListings(doc)
	local postBody = doc:selectFirst("article")
	local content = postBody:selectFirst(".entry-content")
	local jpPost = content:selectFirst("#jp-post-flair")
	if jpPost then jpPost:remove() end

	return mapNotNil(content:select("a"), function (v)
		local url = v:attr("href")
		if not contains(url, "cclawtranslations.home.blog") then
			return nil
		end
		local _parent = v:parent()
		if not _parent then
			return nil
		end

		local _temp = Novel {
			title = v:text(),
			link = shrinkURL(url)
		}
		local imgNode = findImageNode(_parent)

		if imgNode then
			_temp:setImageURL(imgNode:attr("src"))
		end
		return _temp
	end)
end

--- @param elem Element|nil
--- @return Element|nil
local function findVolumeText(elem)
	if not elem then
		return nil
	end

	local prevSib = elem:previousElementSibling()
	if prevSib then
		local className = prevSib:attr("class")
		if contains(className, "wp-block-heading") then
			return prevSib
		end
		return findVolumeText(prevSib)
	end
	return nil
end

--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, loadChapters)
	local postBody = doc:selectFirst("article")
	local content = postBody:selectFirst(".entry-content")
	local postTitle = postBody:selectFirst(".entry-title"):text()
	-- remove the "ToC" text
	local upperPostTitle = postTitle:upper()
	local tocTextIdx = upperPostTitle:find("TOC", 0, true)
	if tocTextIdx then
		postTitle = postTitle:sub(1, tocTextIdx - 1)
	end

	local info = NovelInfo {
		title = postTitle,
	}

	local imageTarget = content:selectFirst("img")
	if imageTarget then
		info:setImageURL(imageTarget:attr("src"))
	end

	if loadChapters then
		local chapters = {}
		map(content:select("a"), function (v)
			local url = v:attr("href")
			if not contains(url, "cclawtranslations.home.blog") then
				return nil
			end
			local tempText = v:text()
			local _parent = v:parent()
			if not _parent then
				return nil
			end
			local volNode = findVolumeText(_parent)
			if volNode then
				tempText = volNode:text() .. " " .. tempText
			end
			-- we want to get the heading text
			local _temp = NovelChapter {
				order = #chapters + 1,
				title = tempText,
				link = shrinkURL(url)
			}
			chapters[#chapters + 1] = _temp
		end)
		info:setChapters(AsList(chapters))
	end
	return info
end

return {
	id = 24903,
	name = "CClaw Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/CClawTL.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Ongoing", false, function ()
			return parseListings(GETDocument("https://cclawtranslations.home.blog/ongoing-projects/"))
		end),
		Listing("Completed", false, function ()
			return parseListings(GETDocument("https://cclawtranslations.home.blog/completed-projects/"))
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
