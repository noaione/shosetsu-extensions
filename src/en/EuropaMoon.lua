-- {"id":376794,"ver":"0.2.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://europaisacoolmoon.wordpress.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-europaisacoolmoon%.wordpress%.com", "")
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
    WPCommon.cleanupElement(p)
    WPCommon.cleanupPassages(p:select("p"), false)

    return p
end

local function parseNovelListing()
    local doc = GETDocument(baseURL)
    local menuPrimary = doc:selectFirst("ul#menu-primary") or doc:selectFirst("ul#menu-main")

    local _novels = {}
    map(menuPrimary:children(), function(v)
        local linkEl = v:selectFirst("a")
        local link = linkEl:attr("href")
        local text = linkEl:text()
        if not WPCommon.contains(link, "/home/") then return end

        _novels[#_novels + 1] = Novel {
            title = text,
            link = shrinkURL(link)
        }
    end)

    return _novels
end

return {
    id = 376794,
    name = "Europa is a cool moon",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/EuropaMoon.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, parseNovelListing)
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(baseURL .. novelURL)
        local baseArticles = doc:selectFirst("article")
        local content = baseArticles:selectFirst(".entry-content")


        local info = NovelInfo {
            title = baseArticles:selectFirst(".entry-title"):text(),
        }

        local imageTarget = content:selectFirst("img")
        if imageTarget then
            info:setImageURL(imageTarget:attr("src"))
        end

        if loadChapters then
            info:setChapters(AsList(mapNotNil(content:select("p a"), function (v, i)
                local chUrl = v:attr("href")
                return (chUrl:find("europaisacoolmoon.wordpress.com", 0, true)) and
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
