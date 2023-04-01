-- {"id":26015,"ver":"0.2.0","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://shirusekaitranslations.wordpress.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-shirusekaitranslations.wordpress.com", "")
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
    local allElements = p:select("p")
    WPCommon.cleanupPassages(allElements, true)
    return p
end

return {
    id = 26015,
    name = "Shiru Sekai Translations",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/ShiruSekai.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function(data)
            local doc = GETDocument(baseURL)
            return map(flatten(mapNotNil(doc:selectFirst("ul#top-menu"):children(), function(v)
                local text = v:selectFirst("a"):text()
                return (text:find("Novels", 0, true)) and
                        map(v:selectFirst("ul.sub-menu"):select("> li > a"), function(v) return v end)
            end)), function(v)
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
        local content = doc:selectFirst("article")

        local info = NovelInfo {
            title = content:selectFirst(".entry-title"):text(),
        }

        local imageTarget = content:selectFirst("img")
        if imageTarget then
            info:setImageURL(imageTarget:attr("src"))
        end

        if loadChapters then
            info:setChapters(AsList(mapNotNil(content:selectFirst(".entry-content"):select("li a"), function (v, i)
                local chUrl = v:attr("href")
                local isShareLink = (chUrl:find("?share=", 0, true) or chUrl:find("&share=")) and true or false
                return (chUrl:find("shirusekaitranslations.wordpress.com", 0, true) and not isShareLink) and
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
