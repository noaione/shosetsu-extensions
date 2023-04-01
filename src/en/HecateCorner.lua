-- {"id":213871,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://hecatescorner.wordpress.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-hecatescorner%.wordpress%.com", "")
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
    if WPCommon.contains(classData, "wordads") then
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
        title = "A Maiden's Unwanted Heroic Epic",
        link = shrinkURL("https://hecatescorner.wordpress.com/a-maidens-unwanted-heroic-epic/"),
    }
    _novels[#_novels + 1] = Novel {
        title = "Lightning Empress Maid",
        link = shrinkURL("https://hecatescorner.wordpress.com/lightning-empress-maid/"),
    }
    return _novels
end

--- @param doc Document
--- @param loadChapters boolean
local function parseNovelInfo(doc, loadChapters)
    local sectionMain = doc:selectFirst("article")
    local pageTitle = sectionMain:selectFirst(".entry-title")
    local contents = sectionMain:selectFirst(".entry-content")
    WPCommon.cleanupElement(contents)

    local info = NovelInfo {
        title = pageTitle:text()
    }
    local img = contents:selectFirst("img")
    if img then
        info:setImageURL(img:attr("src"))
    end

    if loadChapters then
        local chapters = {}
        map(contents:select("p a"), function (v)
            if not WPCommon.contains(v:attr("href"), "hecatescorner.wordpress.com") then
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
    id = 213871,
    name = "Hecate's Corner",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/HecateCorner.png",
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
