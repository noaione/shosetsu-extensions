-- {"id":954056,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon");
local baseURL = "https://tigertranslations.org"

local function startsWith(data, start)
    return data:sub(1, #start) == start
end

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-tigertranslations%.org", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    if startsWith(url, "/") then
        return baseURL .. url
    end
    return baseURL .. "/" .. url
end

--- @param imgEl Element
--- @return string
local function getImageUrl(imgEl)
    local imgOrig = imgEl:attr("data-orig-file")
    if imgOrig then
        return imgOrig
    end
    local largeFile = imgEl:attr("data-large-file")
    if largeFile then
        return largeFile
    end
    return imgEl:attr("src")
end

--- @param doc Document
--- @return Novel[]
local function parseListing()
    local doc = GETDocument(baseURL)

    local _novels = {}
    map(doc:select("#nav > li"), function (v)
        local targetA = v:selectFirst("a")
        local link = shrinkURL(targetA:attr("href"))
        local title = targetA:text()

        local novel = Novel {
            title = title,
            link = link,
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

    local content = doc:selectFirst(".the-content")

    local novel = NovelInfo {
        title = doc:selectFirst("h1.entry-title"):text(),
        language = "English"
    }

    local novelCover = content:selectFirst("img")
    if novelCover then
        novel:setImageURL(getImageUrl(novelCover))
    end

    if loadChapters then
        -- load chapters
        local _loadedChapters = {}
        map(content:select("> p > a"), function (v)
            local linked = v:attr("href")
            if WPCommon.contains(linked, "tigertranslations.org") then
                _loadedChapters[#_loadedChapters + 1] = NovelChapter {
                    order = #_loadedChapters + 1,
                    title = v:text(),
                    link = shrinkURL(linked)
                }
            end
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

    local contents = section:selectFirst(".the-content")
    map(contents:select("> p"), function (v)
        local classId = v:attr("id")
        if WPCommon.contains(classId, "quads") then
            v:remove()
            return
        end
        local className = v:attr("class")
        if WPCommon.contains(className, "taxonomies") then
            v:remove()
            return
        end
        if WPCommon.cleanupElement(v) then
            return
        end

        -- remove navigation
        local deletedAlready = false;
        map(v:select("a"), function (a)
            if deletedAlready then
                return
            end

            local text = a:text():lower()
            if WPCommon.contains(text, "next chapter") or WPCommon.contains(text, "previous chapter") then
                v:remove()
                deletedAlready = true
            end
        end)
    end)

    local title = section:selectFirst(".entry-title")

    contents:child(0):before("<h2 style='text-align:center'>" .. title:text() .. "</h2><hr/>")

    return pageOfElem(contents)
end

return {
    id = 954056,
    name = "Tiger Translations",
    baseURL = baseURL,

    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/TigerTranslations.png",
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
