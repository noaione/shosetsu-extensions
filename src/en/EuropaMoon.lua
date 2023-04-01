-- {"id":376794,"ver":"0.2.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

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

return {
    id = 376794,
    name = "Europa is a cool moon",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/EuropaMoon.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function(data)
            local doc = GETDocument(baseURL)
            -- desktop version
            return map(flatten(mapNotNil(doc:selectFirst("ul#menu-primary"):children(), function (v)
                local linky = v:selectFirst("a")
                return (linky:attr("href"):find("/home/")) and
                    map(v:select("a"), function (ev) return ev end)
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
