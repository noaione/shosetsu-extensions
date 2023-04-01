-- {"id":376796,"ver":"0.2.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://toastytranslations.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-toastytranslations%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

--- @param v Element
local function passageCleanup(v)
    if WPCommon.cleanupElement(v) then
        return
    end
    if WPCommon.isTocRelated(v:text()) then
        v:remove()
        return
    end
    local classData = v:attr("class")
    local isTocButton = classData and classData:find("wp-block-buttons", 0, true) and true or false
    if isTocButton then
        v:remove()
        return
    end
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#main article")
    local p = content:selectFirst(".entry-content")

    WPCommon.cleanupElement(p)

    map(p:select("p"), passageCleanup)
    map(p:select("div"), passageCleanup)

    local title = content:selectFirst(".entry-title")
    if title then
        p:child(0):before("<h2>" .. title:text() .. "</h2><hr/>")
    end

    return p
end

return {
    id = 376796,
    name = "Toasty Translations",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/ToastyTL.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function(data)
            local doc = GETDocument(baseURL)
            -- desktop version
            return map(flatten(mapNotNil(doc:selectFirst("ul.wp-block-navigation__container"):children(), function (v)
                local linky = v:selectFirst("a")
                local linkText = linky:text()
                return (linkText:find("All Translations")) and
                    map(v:select("ul li a"), function (ev) return ev end)
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
            local counter = 0.0
            info:setChapters(AsList(mapNotNil(content:select("ul li a"), function (v)
                local chUrl = v:attr("href")
                local isShareLink = (chUrl:find("?share=", 0, true) or chUrl:find("&share=")) and true or false
                counter = counter + 1.0
                return (chUrl:find("toastytranslations.com", 0, true) and not isShareLink) and
                    NovelChapter {
                        order = counter,
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
