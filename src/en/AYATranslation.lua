-- {"id":24271,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://yuriko-aya.cc"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-yuriko%-aya%.cc", "")
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
    local postBody = doc:selectFirst("#main > article")
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
local function parseListings(doc)
    local navBar = doc:selectFirst("ul#menu-navbar")

    --- @type Novel[]
    local _novels = {}
    map(navBar:select("> li"), function (v)
        local aref = v:selectFirst("a")
        if not aref then
            return
        end
        local areftext = aref:text()
        if not WPCommon.contains(areftext, "Index") then
            return
        end

        -- sub menu
        local subMenu = v:selectFirst("ul.sub-menu")
        map(subMenu:select("li a"), function (vv)
            _novels[#_novels + 1] = Novel {
                title = vv:text(),
                link = shrinkURL(vv:attr("href")),
            }
        end)
    end)
    return _novels
end


--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, loadChapters)
    local sectionMain = doc:selectFirst("#primary")
    local pageTitle = sectionMain:selectFirst(".page-title")

    -- WPCommon.cleanupElement(content)

    local info = NovelInfo {
        title = pageTitle:text(),
    }

    if loadChapters then
        local chapters = {}
        map(sectionMain:select("article"), function (v)
            local entryHeader = v:selectFirst(".entry-header")
            local entryUrl = entryHeader:selectFirst("a")
            local _temp = NovelChapter {
                order = #chapters + 1,
                title = entryUrl:text(),
                link = shrinkURL(entryUrl:attr("href")),
            }
            chapters[#chapters + 1] = _temp
        end)
        info:setChapters(AsList(chapters))
    end
    return info
end

return {
    id = 24271,
    name = "AYA Translation",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/AyaTL.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function ()
            return parseListings(GETDocument("https://yuriko-aya.cc/"))
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
