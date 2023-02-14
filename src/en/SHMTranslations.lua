-- {"id":176796,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://shmtranslations.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-shmtranslations%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param v Element
local function passageCleanup(v)
	if WPCommon.cleanupElement(v) then
		return
	end
	if WPCommon.isTocRelated(v:text()) then
		v:remove()
		return
	end
	local classData = v:attr("class")
	local isTocButton = classData and classData:find("wp-block-buttons", 0, true) and true or false
	if isTocButton then
		v:remove()
		return
	end
	if WPCommon.contains(classData, "ai-viewport-") then
		v:remove()
		return
	end
	-- nuke "SHMtranslation" watermark, it's fucking annoying as an actual reader
	local text = v:text()
	if WPCommon.contains(text:upper(), "SHMTRANSLATION") then
		v:remove()
		return
	end
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("main")
    local p = content:selectFirst(".entry-content")

	WPCommon.cleanupElement(p)

	map(p:select("p"), passageCleanup)
	map(p:select("div"), passageCleanup)

	local title = content:selectFirst(".wp-block-post-title")
	if title then
		p:child(0):before("<h2>" .. title:text() .. "</h2><hr/>")
	end

    return p
end

return {
	id = 176796,
	name = "SHM Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/SHMTranslations.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			-- desktop version
			return map(flatten(mapNotNil(doc:selectFirst("#modal-1-content ul"):children(), function (v)
				local linky = v:selectFirst("a")
				local linkText = linky:text()
				return (linkText:find("Ongoing") or linkText:find("Completed")) and
					map(v:select("ul li a"), function (ev) return ev end)
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
		local baseArticles = doc:selectFirst("main > .entry-content")

		local info = NovelInfo {
			title = baseArticles:selectFirst(".wp-block-heading"):text(),
		}

		local imageTarget = baseArticles:selectFirst("img")
		if imageTarget then
			info:setImageURL(imageTarget:attr("src"))
		end

		-- wp-block-media-text__content
		local description = baseArticles:selectFirst(".wp-block-media-text__content")
		if description then
			info:setDescription(description:text())
		else
			local figcaption = baseArticles:selectFirst("figcaption")
			if figcaption then
				info:setDescription(figcaption:text())
			end
		end

		if loadChapters then
			local counter = 0.0
			-- wp-block-ub-content-toggle-accordion darkmysite_style_txt_border darkmysite_processed
			local _chapters = {}
			map(baseArticles:select(".wp-block-ub-content-toggle-accordion"), function (accord)
				local accordContent = accord:selectFirst(".wp-block-ub-content-toggle-accordion-content-wrap")
				if accordContent then
					map(accordContent:select("a"), function (v)
						local href = v:attr("href")
						if not WPCommon.contains(href, "shmtranslations.com") then
							return
						end
						local text = v:text()
						if not text or text == "" then
							return
						end
						if WPCommon.contains(text, "Quiz ") and WPCommon.contains(novelURL, "isekai-nonbiri") then
							return
						end
						counter = counter + 1.0
						_chapters[#_chapters + 1] = NovelChapter {
							order = counter,
							title = text,
							link = shrinkURL(href)
						}
					end)
				end
			end)
			info:setChapters(AsList(_chapters))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
