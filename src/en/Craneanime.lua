-- {"id":221710,"ver":"0.2.0","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://translation.craneanime.xyz"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-translation%.craneanime%.xyz", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param testString string
--- @return boolean
local function isTocRelated(testString)
	testString = testString:lower()

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
    local content = doc:selectFirst("article")
    local p = content:selectFirst(".entry-content")

	local dark_switch = p:selectFirst("div.wp-dark-mode-switcher")
	if dark_switch then dark_switch:remove() end

	map(p:children(), function (v)
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
	local chTitle = content:selectFirst(".entry-title")
	if chTitle then
		local title = chTitle:text()
		p:child(0):before("<h2>" .. title .. "</h2>")
	end

    return p
end

return {
	id = 221710,
	name = "Craneanime Translation",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Craneanime.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument("https://translation.craneanime.xyz/library/")
			local content = doc:selectFirst(".entry-content")
			return map(content:select("figure"), function (v)
				return Novel {
					title = v:selectFirst("figcaption"):text(),
					imageURL = v:selectFirst("img"):attr("src"),
					link = shrinkURL(v:selectFirst("a"):attr("href"))
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local innerWrap = doc:selectFirst("#main article")

		local title = innerWrap:selectFirst(".entry-title")

		local info = NovelInfo {
			title = title:text(),
		}

		local content = innerWrap:selectFirst(".entry-content")

		local imageTarget = content:selectFirst("img")
		if imageTarget then
			info:setImageURL(imageTarget:attr("src"))
		end

		if loadChapters then
			info:setChapters(AsList(mapNotNil(content:select("p a"), function (v, i)
				local chUrl = v:attr("href")
				return (chUrl:find("translation.craneanime.xyz", 0, true) and v:children():size() < 1) and
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
