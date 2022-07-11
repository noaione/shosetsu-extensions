-- {"id":376754,"ver":"0.1.1","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://experimentaltranslations.com"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-experimentaltranslations%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#main article")
    local p = content:selectFirst(".entry-content")

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    local allElements = p:select("p")
	map(allElements, function (v)
		local hasToCmark = v:text():find("⊥", 0, true) and true or false
		local style = v:attr("style")
		local isAlignCenter = style and style:find("text-align", 0, true) and style:find("center", 0, true) and true or false
		local isValidToc = isAlignCenter and hasToCmark and true or false
		if isValidToc then
			v:remove()
		end
		if v:id():find("atatags") then
			v:remove()
		end
	end)

    return p
end

-- filter the list of projects to only those that are in the table
--- @param url string
local function checkIfValidProject(pageUrl)
	if pageUrl:find("/ongoing/", 0, true) then
		return false
	end
	if pageUrl:find("/finished/", 0, true) then
		return false
	end
	local shrinked = shrinkURL(pageUrl)
	if shrinked:find("/2020/03", 0, true) then
		return false
	end
	if shrinked:find("-images", 0, true) and shrinked:find("/the-villainous") and true or false then
		return false
	end
	return true
end

return {
	id = 376754,
	name = "Experimental Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/ExperimentalTL.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			-- desktop version
			return map(flatten(mapNotNil(doc:selectFirst("ul#primary-menu"):children(), function (v)
				return mapNotNil(v:select("a"), function (ev)
					return checkIfValidProject(ev:attr("href")) and ev
				end)
			end)), function (v)
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
		local baseArticles = doc:selectFirst("article")
		local content = baseArticles:selectFirst(".entry-content")

		-- local ongoingProject = getProjectNav(doc, "li#menu-item-5787")
		-- local finishedProject = getProjectNav(doc, "li#menu-item-12566")

		local info = NovelInfo {
			title = baseArticles:selectFirst(".entry-title"):text(),
		}

		local imageTarget = content:selectFirst("img")
		if imageTarget then
			info.setImageURL(imageTarget:attr("src"))
		end

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
			info:setChapters(AsList(mapNotNil(content:select("p a"), function (v, i)
				local chUrl = v:attr("href")
				return (chUrl:find("experimentaltranslations.com", 0, true)) and
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
