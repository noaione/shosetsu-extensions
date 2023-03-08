-- {"id":24371,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://tintanton.wordpress.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-tintanton%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end


--- @param v Element
local function passageCleanup(v)
	local style = v:attr("style")
	local isAlignment = WPCommon.contains(style, "text-align")
	local isCenterize = WPCommon.contains(style, "center")
	local isValidTocData = WPCommon.isTocRelated(v:text()) and isAlignment and isCenterize and true or false
	if isValidTocData then
		v:remove()
		return
	end
	local classData = v:attr("class")
	if WPCommon.contains(classData, "row") then
		local firstChild = v:child(0)
		if WPCommon.contains(firstChild:attr("class"), "percanav") then
			v:remove()
			return
		end
	end
	local tagId = v:attr("id")
	if WPCommon.contains(tagId, "like-post-wrapper") then
		v:remove()
		return
	end
	if WPCommon.contains(tagId, "jp-relatedposts") then
		v:remove()
		return
	end
	if WPCommon.contains(classData, "switches") then
		v:remove()
		return
	end
	if WPCommon.contains(classData, "sharedaddy") then 
		v:remove()
		return
	end
	local adsByGoogle = v:selectFirst("ins.adsbygoogle")
	if adsByGoogle then
		adsByGoogle:remove()
	end
end

--- @param paragraph Element
local function cleanupChildStyle(paragraph)
	map(paragraph:select("span"), function (v)
		v:removeAttr("style")
	end)
	paragraph:removeAttr("style")
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
	local postBody = doc:selectFirst("article")
	local content = postBody:selectFirst(".entry-content")

	WPCommon.cleanupElement(content)
	map(content:select(".switches"), function (v)
		v:remove()
	end)

	map(content:select("> p"), passageCleanup)
	map(content:select("> div"), passageCleanup)
	map(content:select("p"), cleanupChildStyle)

	-- add title
	local postTitle = postBody:selectFirst(".entry-title")
	if postTitle then
		local title = postTitle:text()
		content:child(0):before("<h2>" .. title .. "</h2><hr/>")
	end

    return content
end

--- @param doc Document
local function getListings()
	--- @type Novel[]
	local _novels = {}
	_novels[#_novels + 1] = Novel {
		title = "I, the hopeless sister, love my sister",
		link = shrinkURL("https://tintanton.wordpress.com/i-the-hopeless-sister-love-my-sister/"),
	}
	_novels[#_novels + 1] = Novel {
		title = "Isekai de Kojiin wo Hiraita kedo, Naze ka Darehitori Sudatou to Shinai Ken",
		link = shrinkURL("https://tintanton.wordpress.com/isekai/"),
	}
	_novels[#_novels + 1] = Novel {
		title = "The Hero Who Returned Remains the Strongest in the Modern World",
		link = shrinkURL("https://tintanton.wordpress.com/the-hero-who-returned-remains-the-strongest-in-the-modern-world/"),
	}
	return _novels
end

--- @param text string
local function stripTitle(text)
	-- remove suffix dot
	text = text:gsub("%.$", "")
	-- remove table of contents at the end
	text = text:gsub("table of contents$", "")
	-- strip space
	text = text:gsub("^%s*(.-)%s*$", "%1")
	-- remove Web novel
	text = text:gsub("web novel$", "")
	-- strip space
	text = text:gsub("^%s*(.-)%s*$", "%1")
	return text
end

--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, loadChapters)
	local sectionMain = doc:selectFirst("article")
	local pageTitle = sectionMain:selectFirst(".entry-title")
	local contents = sectionMain:selectFirst(".entry-content")
	WPCommon.cleanupElement(contents)

	local info = NovelInfo {
		title = stripTitle(pageTitle:text()),
	}

	if loadChapters then
		local chapters = {}
		map(contents:select("a"), function (v)
			if not WPCommon.contains(v:attr("href"), "tintanton.wordpress.com") then
				return
			end
			local _temp = NovelChapter {
				order = #chapters + 1,
				title = v:text(),
				link = shrinkURL(v:attr("href")),
			}
			chapters[#chapters + 1] = _temp
		end)
		info:setChapters(AsList(chapters))
	end
	return info
end

return {
	id = 24371,
	name = "Tintan",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Tintan.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function ()
			return getListings()
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
