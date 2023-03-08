-- {"id":24971,"ver":"0.1.4","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://re-library.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-re%-library%.com", "")
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
	if WPCommon.contains(classData, "sharedaddy") then 
		v:remove()
		return
	end
    local text = v:text():lower()
    if WPCommon.contains(text, "this chapter is provided") or WPCommon.contains(text, "please visit re:library") then
        v:remove()
        return
    end
    local nextHeader = v:selectFirst("a")
    if nextHeader and WPCommon.contains(nextHeader:attr("href"), "patreon.com") then
        v:remove()
        return
    end
	local adsByGoogle = v:selectFirst("ins.adsbygoogle")
	if adsByGoogle then
		adsByGoogle:remove()
	end
end

--- @param v Element
local function reappendStyle(v)
    local style = v:attr("style")
    if WPCommon.contains(style, "text-align") then
        -- extract the alignment, some obvious format:
        -- text-align: center;
        -- text-align: center
        -- text-align:center;
        -- text-align:center
        -- there might also be other style, just ignore it
        local alignment = style:match("text%-align%:%s*%w*%s*;?")
        -- get the alignment
        if alignment then
            return alignment
        end
    end
    return nil
end

--- @param paragraph Element
local function cleanupChildStyle(paragraph)
	map(paragraph:select("span"), function (v)
        local reappend = reappendStyle(v)
		v:removeAttr("style")
        if reappend then
            v:attr("style", reappend)
        end
	end)
    local reappend = reappendStyle(paragraph)
	paragraph:removeAttr("style")
    if reappend then
        paragraph:attr("style", reappend)
    end
end

--- @param suButton Element
local function isOneShotPage(suButton)
    if not suButton then return false end
    local suButtonText = suButton:text()
    if not suButtonText then return false end
    return WPCommon.contains(suButtonText:lower(), "leave a comment")
end

--- @param elem Element
local function isIndex(elem)
    local childA = elem:selectFirst("a")
    if not childA then return false end
    local href = childA:attr("href")
    if not href then return false end
    local text = childA:text()
    if WPCommon.contains(href, "re-library.com") and WPCommon.contains(text:lower(), "index") then
        return true
    end
    return false
end

--- @param content Element
local function nukeNavigation(content)
    local prevPageLink = content:selectFirst(".prevPageLink")
    local nextPageLink = content:selectFirst(".nextPageLink")
    if prevPageLink then
        prevPageLink:remove()
    end
    if nextPageLink then
        local indexLink = nextPageLink:nextElementSibling()
        nextPageLink:remove()
        if indexLink and isIndex(indexLink) then
            indexLink:remove()
        end
    end
end

--- @param content Element
local function countParagraph(content)
    local c = 0
    map(content:select("> p"), function (v)
        c = c + 1
    end)
    return c
end

--- @param content Element
local function findParagraphText(content)
    -- find a <div> that contains more than 3 <p>
    local divs = content:select("> div")
    --- @type Element
    local selectDiv = nil;
    map(divs, function (v)
        local pCount = countParagraph(v)
        if pCount > 3 and selectDiv == nil then
            selectDiv = v
        end
    end)
    return selectDiv
end

--- @param content Element
local function parsePageCommon(content)
	WPCommon.cleanupElement(content)

    -- subutton
    local suButton = content:selectFirst(".su-button")
    if suButton then
        local suButtonParent = suButton:parent()
        if not WPCommon.contains(suButtonParent:attr("class"), "entry-content") then
            suButtonParent:remove()
        else
            suButton:remove()
        end
    end
    nukeNavigation(content)
    nukeNavigation(content)

    local pSpan = content:selectFirst("> p > span")
    if pSpan then
        local pSpanId = pSpan:attr("id")
        if WPCommon.contains(pSpanId, "more-") then
            pSpan:parent():remove()
        end
    end

    -- minimum of 3 paragraph required to be marked as "content"
    if countParagraph(content) < 3 then
        local contentParagraph = findParagraphText(content)
        if contentParagraph then
            content = contentParagraph
        else
            return Document("Failed to parse page, please report to https://github.com/noaione/shosetsu-extensions")
        end
    end

    -- sometimes, the actual content is located in a <div>

	map(content:select("> p"), passageCleanup)
	map(content:select("> div"), passageCleanup)
	map(content:select("p"), cleanupChildStyle)

    return content
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
	local postBody = doc:selectFirst("article")
	local content = parsePageCommon(postBody:selectFirst(".entry-content"))

	-- add title
	local postTitle = postBody:selectFirst(".entry-title")
	if postTitle then
		local title = postTitle:text()
		content:child(0):before("<h2>" .. title .. "</h2><hr/>")
	end

    return content
end

--- @param elem Element|nil
--- @return Element|nil
local function findOneshotParagraphNode(elem)
	if not elem then
		return nil
	end

	local nextSib = elem:nextElementSibling()
	if nextSib then
        local suButton = nextSib:selectFirst(".su-button")
        if isOneShotPage(suButton) then
            local nextNode = nextSib:nextElementSibling()
            if nextNode then
                return nextNode:parent()
            end
            return nextSib:parent() -- found comment node, return it
        end
        local prevSib = nextSib:previousElementSibling()
        prevSib:remove()
		return findOneshotParagraphNode(nextSib)
	end
	return nil
end

local function parsePageOneshot(url)
    local doc = GETDocument(expandURL(url))
	local postBody = doc:selectFirst("article")
	local baseContent = postBody:selectFirst(".entry-content")

    local tempContent = findOneshotParagraphNode(baseContent:child(0))
    if not tempContent then
        return Document("Failed to parse oneshot page, please report to https://github.com/noaione/shosetsu-extensions")
    end
    local content = parsePageCommon(tempContent)

	-- add title
	local postTitle = postBody:selectFirst(".entry-title")
	if postTitle then
		local title = postTitle:text()
		content:child(0):before("<h2>" .. title .. "</h2><hr/>")
	end
    return content
end

--- @param doc Document
local function parseListings(doc)
	local tableMeta = doc:selectFirst(".entry-content > table")

	--- @type Novel[]
	local _novels = {}
    map(tableMeta:select("p a"), function (vv)
        local url = vv:attr("href")
        if not WPCommon.contains(url, "re-library.com") then end
        -- strip leading "* " if exist
        local title = vv:text()
        title = title:gsub("^%*%s", "")
        _novels[#_novels + 1] = Novel {
            title = title,
            link = shrinkURL(url),
        }
    end)
	return _novels
end

--- @param elem Element
local function getSynopsis(elem)
    if not elem then
        return ""
    end
    -- elem will be the #synopsis header.
    -- get all the next <p> until it hit non-<p> element
    local synopsis = ""
    local nextElem = elem:nextElementSibling()
    while nextElem do
        if nextElem:tagName() == "p" then
            synopsis = synopsis .. nextElem:text() .. "\n\n"
        else
            break
        end
        nextElem = nextElem:nextElementSibling()
    end
    -- remove trailing newline
    return synopsis:gsub("\n+$", "")
end

--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, novelUrl, loadChapters)
	local sectionMain = doc:selectFirst("article")
	local pageTitle = sectionMain:selectFirst(".entry-title")

	-- WPCommon.cleanupElement(content)

	local info = NovelInfo {
		title = pageTitle:text(),
	}
    local entryContent = sectionMain:selectFirst(".entry-content")
    local tableRounded = sectionMain:selectFirst(".entry-content > table.rounded")
    local imgCover = tableRounded:selectFirst("img")
    if imgCover then
        info:setImageURL(imgCover:attr("src"))
    end
    local synopsis = entryContent:selectFirst("#synopsis")
    if synopsis then
        info:setDescription(getSynopsis(synopsis))
    end

	if loadChapters then
		local chapters = {}
        local suAccordion = sectionMain:selectFirst(".su-accordion")
        if suAccordion then
            map(suAccordion:select(".su-spoiler"), function (v)
                local contents = v:selectFirst(".su-spoiler-content")
                map(contents:select("li a"), function (vv)
                    chapters[#chapters + 1] = NovelChapter {
                        order = #chapters + 1,
                        title = vv:text(),
                        link = shrinkURL(vv:attr("href")),
                    }
                end)
            end)
        elseif isOneShotPage(entryContent:selectFirst(".su-button")) then
            chapters[#chapters + 1] = NovelChapter {
                order = #chapters + 1,
                title = "Oneshot",
                link = shrinkURL(novelUrl) .. "#shosetsu-oneshot-page", -- extra identifier later when parsing page
            }
        end
        info:setChapters(AsList(chapters))
	end
	return info
end

return {
	id = 24971,
	name = "Re:Library",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/ReLibrary.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Translated Novels", false, function ()
			return parseListings(GETDocument("https://re-library.com/translations/"))
		end),
		Listing("Original Novels", false, function ()
			return parseListings(GETDocument("https://re-library.com/original/"))
		end),
	},

	getPassage = function(chapterURL)
        if WPCommon.contains(chapterURL, "#shosetsu-oneshot-page") then
            return pageOfElem(parsePageOneshot(chapterURL))
        end
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		return parseNovelInfo(doc, novelURL, loadChapters)
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
