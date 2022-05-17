-- {"id":1331219,"ver":"1.1.1","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://bakapervert.wordpress.com"

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

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#content div")
    local p = content:selectFirst(".entry-content")

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    -- get last "p" to remove prev/next links
    local allElements = p:select("p")
    local lastElement = allElements:get(allElements:size()-1)
    if lastElement:children():size() > 0 and lastElement:attr("style"):find("center") then
		lastElement:remove()
    end

    return p
end

--- @param docs Document
--- @param queryData string
--- @return table
local function getProjectNav(docs, queryData)
	return map(docs:selectFirst(queryData):selectFirst("ul.sub-menu"):select("> li > a"), function (v)
		return v:attr("href")
	end)
end

--- @param url string
--- @param projects table
--- @return boolean
local function isProjectInTable(url, projects)
	if not projects then
		return false
	end
	for i = 1, #projects do
		if shrinkURL(projects[i]) == shrinkURL(url) then
			return true
		end
	end
	return false
end


--- @param content Element
--- @return string
local function extractDescription(content)
	-- iter until we match something then stop
	local desc = ""
	local pData = content:select("p")
	local shouldAddToDesc = true
	for i = 0, pData:size() do
		local p = pData:get(i)
		if p and shouldAddToDesc then
			local text = p:text()
			-- check if text empty
			if text:len() > 0 then
				-- check if text is a link
				desc = desc .. text .. "\n"
			end
			if p:selectFirst("a") or p:selectFirst("h2") then
				shouldAddToDesc = false
			end
		end
	end
	return desc
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

		local ongoingProject = getProjectNav(doc, "li#menu-item-5787")
		local finishedProject = getProjectNav(doc, "li#menu-item-12566")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title"):text(),
			imageURL = content:selectFirst("img"):attr("src")
		}

		if isProjectInTable(novelURL, ongoingProject) then
			info:setStatus(NovelStatus.PUBLISHING)
		elseif isProjectInTable(novelURL, finishedProject) then
			info:setStatus(NovelStatus.COMPLETED)
		else
			info:setStatus(NovelStatus.UNKNOWN)
		end

		local infoDesc = extractDescription(content:selectFirst(".entry-content"))
		if infoDesc:len() > 0 then
			info:setDescription(infoDesc)
		end

		if loadChapters then
			bpChCounter = 1
			local actualChapters = map(flatten(mapNotNil(content:selectFirst(".entry-content"):select("p a"), function (v)
				local hrefUrl = v:attr("href")
				return (hrefUrl:find("bakapervert.wordpress.com", 0, true)) and v
			end)), function (v)
				local chInfo = NovelChapter {
					order = bpChCounter,
					title = v:text(),
					link = shrinkURL(v:attr("href")),
				}
				bpChCounter = bpChCounter + 1
				return chInfo
			end)
			info:setChapters(AsList(actualChapters))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
