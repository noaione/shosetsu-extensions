-- {"id":19321,"ver":"0.1.2","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.1"]}

local baseURL = "https://soafp.com"
local settings = {}

local WPCommon = Require("WPCommon")

-- To update, paste the following code in Firefox's console while on the search page:
--
-- term_items = temp0.querySelectorAll(".term_item")
-- parsed_items = []
-- for (let i = 0; i < term_items.length; i++) {
--     term = term_items[i];
--     labelInfo = term.querySelector("label")
--     inputInfo = labelInfo.querySelector("input")
--     parsed_items.push(`${labelInfo.textContent}: ${inputInfo.value}`)
-- }
-- '"' + parsed_items.join(`\",\n\"`) + '"'
--
-- The temp0 can be fetched by right-clicking d-flex part of the Genre wrapper
-- and Selecting "Show in Console"
-- This is just a quick and dirty way to quickly update the genres.
local SWITCH_GENRES = {
    "comedy: Comedy",
    "drama: Drama",
    "fantasy: Fantasy",
    "harem: Harem",
    "isekai: Isekai",
    "oneshot: Oneshot",
    "psychological: Psychological",
    "romance: Romance",
    "school-life: School Life",
    "seinen: Seinen",
    "shounen: Shounen",
    "slice-of-life: Slice of Life",
    "soafp: Soafp",
}
local SWITCH_TAGS = {
    "abusive-characters: Abusive Characters",
    "betrayal: Betrayal",
    "broken-mc: Broken MC",
    "bullying: Bullying",
    "depictions-of-cruelty: Depictions of Cruelty",
    "devoted-love-interests: Devoted Love Interests",
    "drama: Drama",
    "false-accusation: False Accusation",
    "female-protagonist: Female Protagonist",
    "important-past: Important Past",
    "incest: Incest",
    "male-protagonist: Male Protagonist",
    "master-servant-relationship: Master-Servant Relationship",
    "misunderstandings: Misunderstandings",
    "mob-protagonist: Mob Protagonist",
    "multiple-pov: Multiple POV",
    "netorare: Netorare",
    "revenge: Revenge",
    "romance: Romance",
    "school-life: School Life",
    "slaves: Slaves",
    "tragedy: Tragedy",
    "trauma: Trauma",
    "tsundere: Tsundere",
    "wholesome: Wholesome",
    "yandere: Yandere",
    "zama: Zama",
}

--- @param arrays table
local function coerceTristate(arrays, startIndex)
    -- the table is either SWITCH_GENRES or SWITCH_TAGS
    -- the table is a list of strings, each string is a "key: value" pair
    -- we also want index
    local index = startIndex or 1
    local coerced = {}
    print(arrays)
    map(arrays, function (v)
        local key, value = v:match("^(.-):%s*(.-)$")
        coerced[#coerced + 1] = TriStateFilter(index, value)
        index = index + 1
    end)
    return coerced
end

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-soafp.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

---@param srcSetStr string
---@return string|nil
local function getImgSrcSet(srcSetStr)
    -- Get the largest image.
    local max_size, max_url = 0, ""
    for url, size in srcSetStr:gmatch("(http.-) (%d+)w") do
        if tonumber(size) > max_size then
            max_size = tonumber(size)
            max_url = url
        end
    end
    if max_url ~= "" then
        return max_url
    end
    return nil
end

---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
--- Taken from Madara.lua
local function getImgSrc(image_element)
    -- Check srcset:
    local srcset = image_element:attr("srcset")
    if srcset ~= "" then
        local srcSetBig = getImgSrcSet(srcset)
        if srcSetBig then
            return srcSetBig
        end
    end

    -- Check data-lazy-srcset: (unloaded lazyload)
    local dataLazySet = image_element:attr("data-lazy-srcset")
    if dataLazySet ~= "" then
        local srcSetBig = getImgSrcSet(dataLazySet)
        if srcSetBig then
            return srcSetBig
        end
    end

    -- Default to src (the most likely place to be loaded via script):
    return image_element:attr("src")
end

--- @param doc Document
--- @return Novel[]
local function parseListing(doc)
    local section = doc:selectFirst(".search-results")

    local _novels = {}
    map(section:select("> .search-result"), function (v)
        local titleElem = v:selectFirst(".search-link")

        local novel = Novel {
            title = titleElem:text(),
            link = shrinkURL(titleElem:attr("href")),
        }
        _novels[#_novels + 1] = novel
    end)
    return _novels
end

--- @param data table
--- @return Novel[]
local function latestNovel(data)
    local doc = GETDocument(baseURL .. "/search/")
    return parseListing(doc)
end

--- @param arrays table
--- @param startIndex int
--- @param data table
local function buildCoercedResults(arrays, startIndex, data)
    local index = startIndex or 1
    local allowed = {}
    local blocked = {}
    map(arrays, function (v)
        local key, value = v:match("^(.-):%s*(.-)$")
        if data[index] == 1 then
            allowed[#allowed + 1] = key
        elseif data[index] == 2 then
            blocked[#blocked + 1] = key
        end
        index = index + 1
    end)
    return allowed, blocked
end

--- @param data table
--- @return Novel[]
local function doSearch(data)
    local urlReq = baseURL .. "/search/?title="
    local searchString = data[QUERY]
    urlReq = urlReq .. searchString
    local selGenre, blockGenre = buildCoercedResults(SWITCH_GENRES, 101, data)
    for _, v in ipairs(selGenre) do
        urlReq = urlReq .. "&genre[]=" .. v
    end
    for _, v in ipairs(blockGenre) do
        urlReq = urlReq .. "&bl_genre[]=" .. v
    end
    local selTag, blockTag = buildCoercedResults(SWITCH_TAGS, 201, data)
    for _, v in ipairs(selTag) do
        urlReq = urlReq .. "&tag[]=" .. v
    end
    for _, v in ipairs(blockTag) do
        urlReq = urlReq .. "&bl_tag[]=" .. v
    end

    local doc = GETDocument(urlReq)
    return parseListing(doc)
end

--- @param data table
--- @param loadChapters boolean
--- @return NovelInfo
local function getAndParseNovel(novelUrl, loadChapters)
    local doc = GETDocument(expandURL(novelUrl))

    local section = doc:selectFirst("#primary article")
    local title = section:selectFirst(".entry-title"):text()

    local entryContent = section:selectFirst(".entry-content")

    local novel = NovelInfo {
        title = title,
    }
    local imgEl = entryContent:selectFirst(".wp-block-image img")
    if imgEl then
        novel:setImageURL(getImgSrc(imgEl))
    end

    local textDesc = ""
    map(entryContent:select("> p"), function (v)
        textDesc = textDesc .. v:text() .. "\n"
    end)
    textDesc = textDesc:gsub("\n+$", "")
    novel:setDescription(textDesc)

    local entryDetails = section:selectFirst(".entry-details")

    local novelGenres = entryDetails:selectFirst(".genres-links")
    novel:setGenres(map(novelGenres:select("> a"), function (v)
        return v:text()
    end))

    local novelTags = entryDetails:selectFirst(".tags-links")
    novel:setTags(map(novelTags:select("> a"), function (v)
        return v:text()
    end))

    if loadChapters then
        -- load chapters
        local _loadedChapters = {}
        map(entryContent:select("> .lcp_catlist"), function (v)
            map(v:select("li a"), function (vv)
                local href = vv:attr("href")
                if not WPCommon.contains(href, "soafp.com") then -- invalid chapter
                    return
                end
                local chNov = NovelChapter {
                    title = vv:text(),
                    link = shrinkURL(href),
                    order = #_loadedChapters + 1
                }
                _loadedChapters[#_loadedChapters + 1] = chNov
            end)
        end)
        novel:setChapters(AsList(_loadedChapters))
    end
    return novel
end

--- @param chapterUrl string
--- @return any
local function parsePassages(chapterUrl)
    local doc = GETDocument(expandURL(chapterUrl))

    local article = doc:selectFirst("article")
    local content = article:selectFirst(".entry-content")

    local preBar = content:selectFirst(".pre-bar")
    if preBar then preBar:remove() end

    map(content:children(), function (v)
        local deleted = WPCommon.cleanupElement(v)
        if deleted then return end

        local class = v:attr("class")
        if WPCommon.contains(class, "wp-block-buttons") then
            v:remove()
            return
        end

        local textContent = v:text():lower()
        if WPCommon.contains(textContent, "like loading...") then
            v:remove()
            return
        end
    end)

    -- add title
    local postTitle = article:selectFirst(".entry-title")
    if postTitle then
        local title = postTitle:text()
        content:child(0):before("<h2>" .. title .. "</h2><hr/>")
    end

    return pageOfElem(content)
end

return {
    id = 19321,
    name = "Soafp Translations",
    baseURL = baseURL,

    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Soafp.png",
    hasSearch = true,
    hasCloudFlare = false,

    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, latestNovel)
    },

    searchFilters = {
        FilterGroup("Genres", coerceTristate(SWITCH_GENRES, 101)),
        FilterGroup("Tags", coerceTristate(SWITCH_TAGS, 201)),
    },

    getPassage = parsePassages,
    parseNovel = getAndParseNovel,

    shrinkURL = shrinkURL,
    expandURL = expandURL,
    search = doSearch,
    updateSetting = function(id, value)
        settings[id] = value
    end
}
