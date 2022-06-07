-- {"id":309841,"ver":"0.1.0","libVer":"1.0.0","author":"N4O"}

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

-- --- @param docs Document
-- --- @param queryData string
-- --- @return table
-- local function getProjectNav(docs, queryData)
-- 	return map(docs:selectFirst(queryData):selectFirst("ul.sub-menu"):select("> li > a"), function (v)
-- 		return v:attr("href")
-- 	end)
-- end

-- --- @param url string
-- --- @param projects table
-- --- @return boolean
-- local function isProjectInTable(url, projects)
-- 	if not projects then
-- 		return false
-- 	end
-- 	for i = 1, #projects do
-- 		if shrinkURL(projects[i]) == shrinkURL(url) then
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end


-- --- @param content Element
-- --- @return string
-- local function extractDescription(content)
-- 	-- iter until we match something then stop
-- 	local desc = ""
-- 	local pData = content:select("p")
-- 	local shouldAddToDesc = true
-- 	for i = 0, pData:size() do
-- 		local p = pData:get(i)
-- 		if p and shouldAddToDesc then
-- 			local text = p:text()
-- 			-- check if text empty
-- 			if text:len() > 0 then
-- 				-- check if text is a link
-- 				desc = desc .. text .. "\n"
-- 			end
-- 			if p:selectFirst("a") or p:selectFirst("h2") then
-- 				shouldAddToDesc = false
-- 			end
-- 		end
-- 	end
-- 	return desc
-- end

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

		-- local ongoingProject = getProjectNav(doc, "li#menu-item-5787")
		-- local finishedProject = getProjectNav(doc, "li#menu-item-12566")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title"):text(),
			imageURL = content:selectFirst("img"):attr("src")
		}		

		-- if isProjectInTable(novelURL, ongoingProject) then
		-- 	info:setStatus(NovelStatus.PUBLISHING)
		-- elseif isProjectInTable(novelURL, finishedProject) then
		-- 	info:setStatus(NovelStatus.COMPLETED)
		-- else
		-- 	info:setStatus(NovelStatus.UNKNOWN)
		-- end

		-- local infoDesc = extractDescription(content:selectFirst(".entry-content"))
		-- if infoDesc:len() > 0 then
		-- 	info:setDescription(infoDesc)
		-- end

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
