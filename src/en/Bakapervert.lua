-- {"id":1331219,"ver":"1.2.2","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://bakapervert.wordpress.com"
local WPCommon = Require("WPCommon")

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

--- @param doc Document
local function propagateToDocument(doc)
    local content = doc:selectFirst(".entry-content")

    local links = mapNotNil(content:select("a"), function(link)
        local href = link:attr("href")
        return href and href:match("^https?://bakapervert%.wordpress%.com") and href
    end)

    if links == nil then
        local firstLink = content:selectFirst("a")
        return GETDocument(expandURL(shrinkURL(firstLink:attr("href"))))
    end

    local fisrtLink = links[1]
    return GETDocument(expandURL(shrinkURL(fisrtLink)))
end

--- @param document Document
--- @return Element
local function selectContent(document)
    local divContent = document:selectFirst("#content div")
    if divContent ~= nil then
        return divContent
    end
    local articleContent = document:selectFirst("#content article")
    return articleContent
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = selectContent(doc)
    local p = content:selectFirst(".entry-content")

    -- check if p is null
    if p == nil then
        doc = propagateToDocument(doc)
        content = selectContent(doc)
        p = content:selectFirst(".entry-content")
    end

    WPCommon.cleanupElement(p)

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    -- get last "p" to remove prev/next links
    local allElements = p:select("p")
    WPCommon.cleanupPassages(allElements, false)

    return p
end

--- @param document Document
--- @return NovelInfo
local function novelParserDesktop(document, loadChapters)
    local content = document:selectFirst("#content div")

    local info = NovelInfo {
        title = content:selectFirst(".entry-title"):text(),
    }

    local imageTarget = content:selectFirst("img")
    if imageTarget then
        info:setImageURL(imageTarget:attr("src"))
    end

    if loadChapters then
        info:setChapters(AsList(mapNotNil(content:selectFirst(".entry-content"):select("p a"), function (v, i)
            local chUrl = v:attr("href")
            return (chUrl:find("bakapervert.wordpress.com", 0, true)) and
                NovelChapter {
                    order = i,
                    title = v:text(),
                    link = shrinkURL(chUrl)
                }
        end)))
    end

    return info
end

--- @param document Document
--- @return NovelInfo
local function novelParserMobile(document, loadChapters)
    local content = document:selectFirst("#content article")
    local info = NovelInfo {
        title = content:selectFirst(".entry-title"):text(),
    }

    local imageTarget = content:selectFirst("img")
    if imageTarget then
        info:setImageURL(imageTarget:attr("src"))
    end

    if loadChapters then
        info:setChapters(AsList(mapNotNil(content:selectFirst(".entry-content"):select("p a"), function (v, i)
            local chUrl = v:attr("href")
            return (chUrl:find("bakapervert.wordpress.com", 0, true)) and
                NovelChapter {
                    order = i,
                    title = v:text(),
                    link = shrinkURL(chUrl)
                }
        end)))
    end

    return info
end


local function novelParserCommon(novelURL, loadChapters)
    local doc = GETDocument(baseURL .. novelURL)
    local bodyClassName = doc:selectFirst("body"):attr("class")
    if WPCommon.contains(bodyClassName, "mobile-theme") then
        return novelParserMobile(doc, loadChapters)
    else
        return novelParserDesktop(doc, loadChapters)
    end
end

--- @param elem Element
local function novelListingParseCommon(elem)
    local _listings = {}
    
    map(elem:select("#menu-menu-1 > li"), function (menu)
        local header = menu:selectFirst("> a")
        local headerText = header:text()
        if WPCommon.contains(headerText:lower(), "projects") then
            map(menu:select("> .sub-menu > li"), function (itemData)
                local link = itemData:selectFirst("> a")

                _listings[#_listings + 1] = Novel {
                    title = link:text(),
                    link = shrinkURL(link:attr("href"))
                }
            end)
        end
    end)

    return _listings
end

local function novelListingCommon()
    local doc = GETDocument(baseURL)
    local bodyClassName = doc:selectFirst("body"):attr("class")
    if WPCommon.contains(bodyClassName, "mobile-theme") then
        return novelListingParseCommon(doc:selectFirst("nav#access > .menu-menu-1-container"))
    else
        return novelListingParseCommon(doc:selectFirst("div#access > .menu-header"))
    end
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
        Listing("Novels", false, novelListingCommon)
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = novelParserCommon,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
