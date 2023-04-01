-- {"id":26016,"ver":"0.2.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://shirokuns.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-shirokuns%.com", "")
end

--- @param url string
--- @return string
local function mapWordpressOldUrl(url)
    -- Change wordpress shirokuns.wordpress.com domain to baseUrl domain
    return url:gsub("shirokuns%.wordpress%.com", "shirokuns.com")
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

    local hestiaImg = p:selectFirst(".wp-post-image")
    if hestiaImg then hestiaImg:remove() end

    local allElements = p:select("p")
    map(allElements, function (v)
        local isRemoved = WPCommon.cleanupElement(v)
        if isRemoved then return end
        local style = v:attr("style")
        local isAlignCenter = style and style:find("text-align", 0, true) and style:find("center", 0, true) and true or false
        local isValidTocData = isAlignCenter and WPCommon.isTocRelated(v:text()) and true or false
        local isPatreonAd = v:text():lower():find("patreon") and v:text("supporter") and true or false
        local isPatronAd = v:text():lower():find("patron") and v:text("supporter") and true or false
        if isValidTocData then
            return v:remove()
        end
        if isPatreonAd or isPatronAd then
            return v:remove()
        end
    end)

    return p
end

return {
    id = 26016,
    name = "ShiroKun's Translation",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/ShiroKunTL.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function(data)
            local doc = GETDocument(baseURL)
            return map(flatten(mapNotNil(doc:selectFirst("ul#menu-main-menu"):children(), function(v)
                local text = v:selectFirst("a"):attr("title")
                return (text:find("Projects", 0, true) or text:find("Series", 0, true)) and
                        map(v:selectFirst("ul.dropdown-menu"):select("> li > a"), function(v) return v end)
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
            title = content:selectFirst(".hestia-title"):text(),
        }

        local imageTarget = content:selectFirst("a img")
        if imageTarget then
            info:setImageURL(imageTarget:attr("src"))
        end

        if loadChapters then
            info:setChapters(AsList(mapNotNil(content:selectFirst(".page-content-wrap"):select("li a"), function (v, i)
                local chUrl = mapWordpressOldUrl(v:attr("href"))
                return (chUrl:find("shirokuns.com", 0, true)) and
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
