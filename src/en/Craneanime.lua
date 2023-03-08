-- {"id":221710,"ver":"0.3.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://translation.craneanime.xyz"
local WPCommon = Require("WPCommon")

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

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("article")
    local p = content:selectFirst(".entry-content")
	WPCommon.cleanupElement(p)
	WPCommon.cleanupPassages(p:children(), true)

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
