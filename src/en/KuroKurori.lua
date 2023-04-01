-- {"id":309841,"ver":"0.2.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://kurokurori.wordpress.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-kurokurori%.wordpress%.com", "")
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
    WPCommon.cleanupPassages(p:select("p"))
    return p
end

return {
    id = 309841,
    name = "Kuro Kurori's Lounge",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/KuroKurori.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function(data)
            local doc = GETDocument(baseURL)
            return map(flatten(mapNotNil(doc:selectFirst("ul#primary-menu"):children(), function(v)
                local text = v:selectFirst("a"):text()
                return (text:find("Our Girls", 0, true)) and
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
        local content = doc:selectFirst("#main > article")

        local info = NovelInfo {
            title = content:selectFirst(".entry-title"):text(),
        }		

        local imageTarget = content:selectFirst("img")
        if imageTarget then
            info:setImageURL(imageTarget:attr("src"))
        end

        if loadChapters then
            local mainContents = content:select("div.entry-content > div.entry-content")
            local lastContent = mainContents:get(mainContents:size() - 1)
            info:setChapters(AsList(mapNotNil(lastContent:select("p a"), function (v, i)
                local chUrl = v:attr("href")
                return (chUrl:find("kurokurori.wordpress.com", 0, true)) and
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
