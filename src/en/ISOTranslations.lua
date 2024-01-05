-- {"id":1238794,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon");
local baseURL = "https://www.isotls.com"

local function startsWith(data, start)
    return data:sub(1, #start) == start
end

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-www%.isotls%.com", ""):gsub("^.-isotls%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    if startsWith(url, "/") then
        return baseURL .. url
    end
    return baseURL .. "/" .. url
end

--- @param doc Document
--- @return Novel[]
local function parseListing()
    local doc = GETDocument(expandURL("/novels/"))
    local novelLists = doc:selectFirst("#novel-list")
    local contentLists = novelLists:selectFirst("ul.content-list")

    local _novels = {}
    map(contentLists:select("> li.content-list-item"), function (v)
        local title = v:selectFirst("> a > p"):text()
        local link = shrinkURL(v:selectFirst("> a"):attr("href"))
        local imgSrc = v:attr("data-img-src")

        local novel = Novel {
            title = title,
            link = link,
            imageURL = imgSrc
        }
        _novels[#_novels + 1] = novel
    end)
    return _novels
end

--- @param data table
--- @param loadChapters boolean
--- @return NovelInfo
local function getAndParseNovel(novelUrl, loadChapters)
    local doc = GETDocument(expandURL(novelUrl))

    local sectionHead = doc:selectFirst("#novel-header")
    local title = sectionHead:selectFirst("h1"):text()

    local novel = NovelInfo {
        title = title,
        language = "English"
    }

    local novelCover = sectionHead:selectFirst(".novel-cover")
    novel:setImageURL(novelCover:attr("src"))

    local synopsis = sectionHead:selectFirst("#synopsis > div")
    if synopsis then
        -- get each paragraph
        local paragraphs = ""
        map(synopsis:select("> p"), function (v)
            paragraphs = paragraphs .. v:text() .. "\n\n"
        end)
        novel:setDescription(paragraphs)
    end

    if loadChapters then
        -- load chapters
        local chapterList = doc:selectFirst("#chapters > ul")
        local _loadedChapters = {}
        map(chapterList:select("> li"), function (v)
            local order = v:attr("data-order")
            local title = v:attr("data-title")

            _loadedChapters[#_loadedChapters + 1] = NovelChapter {
                order = tonumber(order),
                title = title,
                link = shrinkURL(v:selectFirst("a"):attr("href"))
            }
        end)
        novel:setChapters(AsList(_loadedChapters))
    end
    return novel
end

--- @param chapterUrl string
--- @return any
local function parsePassages(chapterUrl)
    local doc = GETDocument(expandURL(chapterUrl))

    local section = doc:selectFirst("article")

    local contents = section:selectFirst(".content")
    map(contents:select("> span"), function (v)
        local className = v:attr("class")
        if WPCommon.contains(className, "ezoic") then
            v:remove()
            return
        end
        if WPCommon.contains(className, "reportline") then
            v:remove()
            return
        end
        if WPCommon.contains(className, "universal-js") then
            v:remove()
            return
        end
        if WPCommon.contains(className, "ez-clear") then
            v:remove()
            return
        end
    end)

    local header = section:selectFirst("header")
    local title = header:selectFirst("h1"):text()

    local novelTitle = header:selectFirst("a"):text()

    contents:child(0):before("<hr />")
    contents:child(0):before("<h2 style='text-align:center'>" .. title .. "</h2><hr/>")
    contents:child(0):before("<h1 style='text-align:center'>" .. novelTitle .. "</h1><hr/>")

    return pageOfElem(contents)
end

return {
    id = 954055,
    name = "ISO Translations",
    baseURL = baseURL,

    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/ISOTranslations.png",
    hasSearch = false,
    hasCloudFlare = false,

    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, parseListing)
    },

    getPassage = parsePassages,
    parseNovel = getAndParseNovel,

    shrinkURL = shrinkURL,
    expandURL = expandURL,
}
