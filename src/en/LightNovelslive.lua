-- {"id":12376124,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["dkjson>=1.0.1"]}

local json = Require("dkjson")

-- 10 pages maximum
local paginatingHardLimit = 9

--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 12376124

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://lightnovels.live"
local readURL = "https://pandapama.com"

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, type)
    if type == KEY_NOVEL_URL then
        return url:gsub("^.-lightnovels%.live", "")
    else
        return url:gsub("^.-pandapama%.com", "")
    end
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url, type)
    local urlSel = baseURL
    if type == KEY_CHAPTER_URL then
        urlSel = readURL
    end
    -- check if url startswith "/"
    if url:sub(1, 1) == "/" then
        return urlSel .. url
    end
    return urlSel .. "/" .. url
end

--- @param document Document
local function parseListingAPI(document)
    local json = json.decode(document:text())

    local _data = {}
    map(json.results, function (novel)
        local title = novel.novel_name
        local _novel = Novel {
            title = title,
            link = "/novel" .. novel.novel_slug,
        }
        if novel.novel_image ~= nil then
            local imageUrl = expandURL(novel.novel_image, KEY_NOVEL_URL)
            _novel:setImageURL(imageUrl)
        end
        _data[#_data + 1] = _novel
    end)

    return _data
end

local function parseUpdatedAt(updatedAt)
    if updatedAt == nil then
        return nil
    end

    -- YYYY-MM-DDTHH:MM:SSZ
    -- we only want the YYYY-MM-DD

    local year, month, day = updatedAt:match("(%d+)-(%d+)-(%d+)")
    return year .. "-" .. month .. "-" .. day
end

--- @param novelId int
local function getAndParseChapters(novelId)
    local url = expandURL("/api/chapters?id=" .. novelId .. "&index=1&limit=15000", KEY_NOVEL_URL)
    local doc = GETDocument(url)

    local jsonData = json.decode(doc:text())
    local _chapters = {}
    map(jsonData.results, function (chapter)
        local updatedAt = chapter.updated_at
        local title = chapter.chapter_name
        local order = chapter.chapter_index
        local urlSlug = "/read" .. chapter.slug

        local _chapter = NovelChapter {
            title = title,
            link = urlSlug,
            order = order,
        }

        if updatedAt ~= nil then
            _chapter:setRelease(parseUpdatedAt(updatedAt))
        end

        _chapters[#_chapters + 1] = _chapter
    end)

    return AsList(_chapters)
end

local function getAndParseNovel(novelUrl, loadChapters)
    local doc = GETDocument(expandURL(novelUrl))

    local nextJSON = json.decode(doc:selectFirst("script#__NEXT_DATA__"):html())
    local pageProps = nextJSON.props.pageProps

    local novelInfo = pageProps.novelInfo

    local novel = NovelInfo {
        title = novelInfo.novel_name,
        description = novelInfo.novel_description,
        status = NovelStatus.UNKNOWN,
    }

    if novelInfo.novel_image ~= nil then
        local imageURL = expandURL(novelInfo.novel_image, KEY_NOVEL_URL)
        novel:setImageURL(imageURL)
    end


    if pageProps.genres then
        local genres = map(pageProps.genres, function (genre) return genre.name end)
        novel:setGenres(genres)
    end
    if pageProps.authors then
        local authors = map(pageProps.authors, function (author) return author.name end)
        novel:setAuthors(authors)
    end

    if novelInfo.status == "Ongoing" then
        novel:setStatus(NovelStatus.PUBLISHING)
    end
    if novelInfo.status == "Completed" then
        novel:setStatus(NovelStatus.COMPLETED)
    end

    if loadChapters then
        novel:setChapters(getAndParseChapters(novelInfo.novel_id))
    end

    return novel
end

--- @param chapterUrl string
local function getAndParsePassage(chapterUrl)
    local doc = GETDocument(expandURL(chapterUrl, KEY_CHAPTER_URL))

    local nextJSON = json.decode(doc:selectFirst("script#__NEXT_DATA__"):html())
    local pageProps = nextJSON.props.pageProps
    local chapterInfo = pageProps.cachedChapterInfo

    local headerPart = "<h2>" .. chapterInfo.chapter_name .. "</h2>"
    local passage = Document(headerPart .. "<div>" .. chapterInfo.content .. "</div>")
    return pageOfElem(passage)
end

local function searchNovel(data)
    local query = data[QUERY]
    local page = data[PAGE]

    if page > paginatingHardLimit then
        return {}
    end

    local indexPage = page * 50

    local url = expandURL("/api/search?keyword=" .. query .. "&index=" .. indexPage .. "&limit=50", KEY_NOVEL_URL)
    
    local doc = GETDocument(url)
    return parseListingAPI(doc)
end

-- Return all properties in a lua table.
return {
    -- Required
    id = id,
    name = "LightNovels.live",
    baseURL = baseURL,
    listings = {
        Listing("Latest", true, function (data)
            local page = data[PAGE]

            if page > paginatingHardLimit then
                return {}
            end

            local indexPage = page * 50
            local url = expandURL("/api/novel/latest-release-novel?index=" .. indexPage .. "&limit=50", KEY_NOVEL_URL)
            
            local doc = GETDocument(url)
            return parseListingAPI(doc)
        end),
        Listing("Hot Novel", true, function (data)
            local page = data[PAGE]

            if page > paginatingHardLimit then
                return {}
            end

            local indexPage = page * 50
            local url = expandURL("/api/novel/hot-novel?index=" .. indexPage .. "&limit=50", KEY_NOVEL_URL)
            
            local doc = GETDocument(url)
            return parseListingAPI(doc)
        end)
    }, -- Must have at least one listing
    getPassage = getAndParsePassage,
    parseNovel = getAndParseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/LightNovelslive.png",
    hasCloudFlare = false,
    hasSearch = true,
    isSearchIncrementing = true,
    chapterType = ChapterType.HTML,
    startIndex = 0,

    -- Required if [hasSearch] is true.
    search = searchNovel,
}
