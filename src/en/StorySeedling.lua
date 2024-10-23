-- {"id":4302,"ver":"2.1.4","libVer":"1.0.0","author":"N4O","dep":["dkjson>=1.0.1","Multipartd>=1.0.0","WPCommon>=1.0.3"]}

local json = Require("dkjson");
local Multipartd = Require("Multipartd");
local WPCommon = Require("WPCommon");

local baseURL = "https://storyseedling.com"

local globalState = {}

-- Filter Keys & Values
local STATUS_FILTER = 2
local STATUS_VALUES = { "All", "Ongoing", "Completed" }
local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Recently Added", "Latest Update", "Random" }
local ORDER_BY_TERMS = { "recent", "latest", "random" }
local GENRE_FILTER = 50
-- To update, paste the following code in Firefox's console while on the search page:
--
-- term_items = temp0.querySelectorAll(".term_item")
-- merged_data = []
-- for (let i = 0; i < temp0.children.length; i++) {
-- 	let child = temp0.children[i];
-- 	let clickState = child.getAttribute("@click").replace("genreState(", "").replace(")", "")
-- 	let genreName = child.querySelector("span").textContent
-- 	merged_data.push(`${genreName}: ${clickState}`)
-- }
-- '"' + merged_data.join(`\",\n\"`) + '"'
--
-- The temp0 can be fetched by right-clicking `flex flex-wrap mt-2` part of the Genre wrapper
-- and Selecting "Show in Console"
-- This is just a quick and dirty way to quickly update the genres.
local GENRE_VALUES = { 
    "Action: 111",
    "Adult: 183",
    "Adventure: 112",
    "BL: 207",
    "Comedy: 153",
    "Drama: 115",
    "Ecchi: 170",
    "Fantasy: 114",
    "Harem: 956",
    "Historical: 178",
    "Horror: 254",
    "Josei: 472",
    "Martial Arts: 1329",
    "Mature: 427",
    "Mecha: 1481",
    "Mystery: 645",
    "Psychological: 515",
    "Reincarnation: 1031",
    "Romance: 108",
    "School Life: 545",
    "Sci-Fi: 113",
    "Seinen: 708",
    "Shoujo: 228",
    "Shoujo Ai: 1403",
    "Shounen: 246",
    "Shounen Ai: 718",
    "Slice of Life: 157",
    "Smut: 736",
    "Sports: 966",
    "Supernatural: 995",
    "Tragedy: 985",
    "Xianxia: 245",
    "Xuanhuan: 428",
    "Yaoi: 184",
    "Yuri: 182",
}


local searchFilters = {
    DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES),
    DropdownFilter(STATUS_FILTER, "Status", STATUS_VALUES),
    FilterGroup("Genre", map(GENRE_VALUES, function(v, i) 
        local KEY_ID = GENRE_FILTER + i
        local key, _ = v:match("^(.-):%s*(.-)$")
        return TriStateFilter(KEY_ID, key)
    end))
}

local function shrinkURL(url)
    return url:gsub("^.-storyseedling%.com", "")
end

local function expandURL(url)
    return baseURL .. url
end

--- @param seriesUrl string
local function rewriteSeriesUrl(seriesUrl)
    -- rewrite from /novel/12345/series-slug
    -- into: /series/12345
    return seriesUrl:gsub("/novel/(%d+)/.*", "/series/%1")
end

--- Rewrite old chapter URLs to new ones
--- @param chapterUrl string
local function rewriteChapterUrl(chapterUrl)
    -- rewrite the following variants:
    -- - /novel/12345/series-slug/chapter-X => /series/12345/X
    -- - /novel/12345/series-slug/chapter-X-Z => /series/12345/X.Z
    -- - /novel/12345/series-slug/chapter-X (extra data) => /series/12345/X (extra data)
    -- - /novel/12345/series-slug/chapter-X-Z (extra data) => /series/12345/X.Z (extra data)
    -- - /novel/12345/series-slug/volume-X-chapter-Y => /series/12345/vX/Y
    -- - /novel/12345/series-slug/volume-X-chapter-Y-Z => /series/12345/vX/Y.Z

    local matches = {
        chapterUrl:match("/novel/(%d+)/([^/]+)/chapter-(%d+)([^/]*)$"),
        chapterUrl:match("/novel/(%d+)/([^/]+)/volume-(%d+)-chapter-(%d+)([^/]*)$")
    }

    if matches[1] then
        local novelId = matches[1]
        local chapterNum = matches[3]
        local extraData = matches[4] or ""
        return "/series/" .. novelId .. "/" .. chapterNum .. extraData
    elseif matches[4] then
        local novelId = matches[2]
        local volume = "v" .. matches[4]
        local chapterNum = matches[5]
        local extraData = matches[6] or ""
        return "/series/" .. novelId .. "/" .. volume .. "/" .. chapterNum .. extraData
    else
        -- Return original URL if no matches found
        return chapterUrl
    end   
end

-- local function getPassage(chapterURL)
--     local chap = GETDocument(expandURL(rewriteChapterUrl(chapterURL))):selectFirst("main")

--     local proseData = chap:selectFirst(".prose")
--     -- Remove empty <p> tags
--     local toRemove = {}
--     proseData:traverse(NodeVisitor(function(v)
--         if v:tagName() == "p" and v:text() == "" then
--             toRemove[#toRemove+1] = v
--         end
--         if v:hasAttr("border") then
--             v:removeAttr("border")
--         end
--     end, nil, true))
--     for _,v in pairs(toRemove) do
--         v:remove()
--     end
--     local notProse = proseData:selectFirst("div.not-prose")
--     if notProse ~= nil then
--         notProse:remove()
--     end
--     return pageOfElem(proseData, true)
-- end

--- @param webpage Document
local function getsn(webpage)
    local axLoad = webpage:selectFirst("div[ax-load]")
    local xData = axLoad:attr("x-data")
    local s, n = xData:match("loadChapter%('([^']+)', '([^']+)'%)")
    return s, n
end

--- @param chapterUrl string
--- @return Document
local function requestPassageInformation(chapterUrl)
    local chapterPage = expandURL(rewriteChapterUrl(chapterUrl))

    local mainPage = GETDocument(chapterPage)

    local s, n = getsn(mainPage)
    print("StorySeedling Random Passage Data:", s, n)

    local headers = HeadersBuilder()
    headers:add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/129.0")
    headers:add("Origin", "https://storyseedling.com")
    headers:add("Referer", chapterPage)
    headers:add("X-Nonce", n)

    -- create table of JSON data
    local jsonData = {
        captcha_response = "",
    }
    local reqData = json.encode(jsonData);

    local res = Request(POST(
        chapterPage .. "/content",
        headers:build(),
        RequestBody(reqData, MediaType("application/json"))
    ))

    local htmlData = res:body():string()

    if res:code() ~= 200 then
        error("Status code is not 200, received " .. res:code());
    end

    if res:headers():get("Content-Type"):sub(1, 16) == "application/json" then
        error("Received JSON response instead of HTML, possible Captcha");
    end

    local doc = Document(htmlData)

    return doc
end

-- Returns the ASCII bytecode of either 'a' or 'A'
local function asciiBase(s)
    return s:lower() == s and ('a'):byte() or ('A'):byte()
end

local minLower = 97
local maxLower = 122
local minUpper = 65
local maxUpper = 90

-- ROT13 is based on Caesar ciphering algorithm, using 13 as a key
local function caesarCipher(str, key)
    -- loop through all characters in the string
    -- and apply ROT13
    local merge = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        local b = c:byte()

        -- check if alphabetic
        if b >= minLower and b <= maxLower or b >= minUpper and b <= maxUpper then
            local base = asciiBase(c)
            -- apply ROT13
            merge = merge .. string.char(((b - base + key) % 26) + base)
        else
            merge = merge .. c
        end
    end
    return merge
end

local function isFuckingGarbage(text)
    -- "Copyrighted sentence owned by Story Seedling", lol lmao even, kys.
    if WPCommon.contains(text:lower(), "storyseedling") then
        return true
    end
    if WPCommon.contains(text:lower(), "story seedling") then
        return true
    end
    if WPCommon.contains(text:lower(), "storyseedling.com") then
        return true
    end
    if WPCommon.contains(text:lower(), "travis translation") then
        return true
    end
    return false
end

local function getPassage(chapterURL)
    local chap = requestPassageInformation(chapterURL)

    -- remove styles
    local style = chap:selectFirst("style")
    if style then
        style:remove()
    end

    -- unrot all <span> instance
    local spanData = chap:select("span")
    map(spanData, function (v)
        local rawText = v:text()

        -- clean space
        local cleanText = rawText:gsub("^%s*(.-)%s*$", "%1")

        if cleanText:lower() == "pbclevtugrq fragrapr bjarq ol fgbel frrqyvat" or cleanText:lower() == "pbclevtugrq fragrapr bjarq ol fgbelfrrqyvat" then
            v:remove()
            return
        end

        -- check if starts with cls and 21 characters
        if rawText:sub(1, 3) == "cls" and rawText:len() == 21 then
            v:remove()
            return
        end

        -- unrot
        local unrot = caesarCipher(rawText, 13)
        v:text(unrot)
    end)

    return pageOfElem(chap, true)
end

--- @param description Element
local function formatDescription(description)
    local synopsis = ""
    local totalNodes = description:childNodeSize()
    for i = 0, totalNodes - 1 do
        local node = description:childNode(i)
        local textData = node:text():gsub("^%s*(.-)%s*$", "%1")
        synopsis = synopsis .. textData .. "\n"
    end
    return synopsis:gsub("\n+$", ""):gsub("%s+$", "")
end


--- @param webpage Document
local function getPostId(webpage)
    local axLoad = webpage:selectFirst("div[ax-load]")
    local xData = axLoad:attr("x-data")
    -- toc('PostID', 'randomData'), get the post ID and random data
    local postId, randomData = xData:match("toc%('([^']+)', '([^']+)'%)")
    return postId, randomData
end


--- @param novelId string
--- @param randomData string
--- @return table
local function getChapterList(novelId, randomData)
    -- build form
    local formBuilder = Multipartd:new()
    formBuilder:add("post", randomData)
    formBuilder:add("id", novelId)
    formBuilder:add("action", "series_toc")

    -- for media type, cut off the first two dashes
    local headers = HeadersBuilder()
    headers:add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/129.0")
    headers:add("Origin", "https://storyseedling.com")
    headers:add("Referer", "https://storyseedling.com/series" .. novelId)

    local resp = Request(POST(
        expandURL("/ajax"),
        headers:build(),
        RequestBody(formBuilder:build(), MediaType(formBuilder:getHeader()))
    ))

    -- json response
    local body = resp:body():string()
    local jsonData = json.decode(body)
    return jsonData.data
end

local function getStatusFromText(text)
    if WPCommon.contains(text, "Ongoing") then
        return NovelStatus.PUBLISHING
    elseif WPCommon.contains(text, "Completed") then
        return NovelStatus.COMPLETED
    elseif WPCommon.contains(text, "Dropped") then
        return NovelStatus.PAUSED
    elseif WPCommon.contains(text, "Hiatus") then
        return NovelStatus.PAUSED
    elseif WPCommon.contains(text, "Cancelled") then
        return NovelStatus.PAUSED
    end
    return NovelStatus(-1)
end

local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(rewriteSeriesUrl(novelURL)))
    local content = doc:selectFirst("main")

    local chapterSelector = content:selectFirst("section[x-data]")
    local gridInInfo = chapterSelector:selectFirst(".lg\\:grid-in-info")
    local gridInContent = chapterSelector:selectFirst(".lg\\:grid-in-content")
    
    local info = NovelInfo {
        title = content:selectFirst("h1.text-2xl"):text(),
        imageURL = content:selectFirst("div.bg-blur"):selectFirst("img"):attr("src"),
        description = formatDescription(gridInContent:selectFirst(".order-2")),
        artists = { "Translator: Story Seedling" },
        genres = map(gridInInfo:select("a[up-deprecated]"), function(v) return v:text() end),
    }

    -- <div class="flex items-center gap-2">
    local firstGridInInfo = content:selectFirst(".lg\\:grid-in-info")
    if firstGridInInfo then
        local status = firstGridInInfo:selectFirst("div.items-center")
        if status then
            local statusDetail = status:selectFirst(".text-sm")
            if statusDetail then
                local statusText = statusDetail:text()
                info:setStatus(getStatusFromText(statusText))
            end
        end
    end

    if loadChapters then
        local novelId, randomData = getPostId(doc)
        print("StorySeedling Random Series Data:", novelId, randomData)
        local chaptersList = getChapterList(novelId, randomData)
        local _chapters = {}
        --- Chapter is ascending order 1 to N
        for i = 1, #chaptersList do
            local v = chaptersList[i]
            if not v.is_locked then
                _chapters[#_chapters + 1] = NovelChapter {
                    order = i,
                    title = v.title,
                    link = shrinkURL(v.url),
                    release = v.date
                }
            end
        end

        info:setChapters(AsList(_chapters))
    end
    return info
end

--- @param listing table
local function parseListing(listing)
    return map(listing.data.posts, function(v)
        return Novel {
            title = v.title,
            link = shrinkURL(v.permalink),
            imageURL = v.thumbnail,
        }
    end)
end

local function getPostData()
    if globalState.postData then
        return globalState.postData
    end

    local webpage = GETDocument(expandURL("/browse/"))

    local axLoad = webpage:selectFirst("div[ax-load]")
    local xData = axLoad:attr("x-data")
    -- browse('RANDOMDATAHERE'), get the random data
    local randomData = xData:match("browse%('([^']+)'%)")

    globalState.postData = randomData

    return randomData
end

local function getSearch(data)
    local query = data[QUERY]
    local page = data[PAGE]
    local orderBy = data[ORDER_BY_FILTER]

    -- get the random data
    local randomData = getPostData()
    print("StorySeedling Random Data:", randomData)

    -- build form
    local formBuilder = Multipartd:new()
    formBuilder:add("search", query or "")

    map(GENRE_VALUES, function(v, i)
        local KEY_ID = GENRE_FILTER + i
        local _, value = v:match("^(.-):%s*(.-)$")
        if data[KEY_ID] == 1 then
            formBuilder:add("includeGenres[]", value)
        elseif data[KEY_ID] == 2 then
            formBuilder:add("excludeGenres[]", value)
        end
    end)

    if orderBy ~= nil then
        formBuilder:add("orderBy", ORDER_BY_TERMS[orderBy + 1])
    else
        formBuilder:add("orderBy", "recent")
    end

    if page > 1 then
        formBuilder:add("curpage", tostring(page))
    end

    formBuilder:add("post", randomData)
    formBuilder:add("action", "fetch_browse")

    -- for media type, cut off the first two dashes
    local headers = HeadersBuilder()
    headers:add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/129.0")
    headers:add("Origin", "https://storyseedling.com")
    headers:add("Referer", "https://storyseedling.com/browse")

    local resp = Request(POST(
        expandURL("/ajax"),
        headers:build(),
        RequestBody(formBuilder:build(), MediaType(formBuilder:getHeader()))
    ))

    -- json response
    local body = resp:body():string()
    local jsonData = json.decode(body)
    return parseListing(jsonData)
end

local function getListing(data)
    return getSearch(data)
end

return {
    id = 4302,
    name = "Story Seedling",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/TravisTranslations.png",
    chapterType = ChapterType.HTML,

    listings = {
        Listing("Latest", true, getListing)
    },
    getPassage = getPassage,
    parseNovel = parseNovel,

    hasSearch = true,
    isSearchIncrementing = true,
    search = getSearch,
    searchFilters = searchFilters,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
