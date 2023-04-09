-- {"id":13640,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","repo":"","dep":["WPCommon>=1.0.0"]}

local WPCommon = Require("WPCommon")

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://nyx-translation.com"


--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url)
    return url:gsub("^.-nyx%-translation%.com", "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url)
    -- Currently the two branches are the same.
    -- Read [shrinkURL] documentation in regards to what you should do.
    -- Hint, this is the opposite.
    return baseURL .. url
end

--- @param url string
local function rewriteUrl(url)
    if WPCommon.contains(url, "nyxtranslation.home.blog") then
        return url:gsub("nyxtranslation.home.blog", "nyx-translation.com")
    end
    return url
end

--- @return Novel[]
local function parseListings()
    local document = GETDocument(baseURL)
    local topNav = document:selectFirst("ul#top-menu")

    -- find the List Novel
    -- print(topNav)
    local _selected = topNav:selectFirst("> li > a:contains(List Novel)"):parent():selectFirst("> .sub-menu")
    local _novels = {}

    map(_selected:select("> li"), function (child)
        local statusFmt = "#shosetsu-status-publishing"
        local aElem = child:selectFirst("> a")
        local statusSel = aElem:text():lower()
        if WPCommon.contains(statusSel, "complete") then
            statusFmt = "#shosetsu-status-completed"
        elseif WPCommon.contains(statusSel, "on hold") then
            statusFmt = "#shosetsu-status-paused"
        elseif WPCommon.contains(statusSel, "dropped") then
            statusFmt = "#shosetsu-status-paused"
        end

        map(child:select(".sub-menu > li"), function (novel)
            local linkElem = novel:selectFirst("> a")
            local novelUrl = linkElem:attr("href")
            local novelTitle = linkElem:text()

            _novels[#_novels + 1] = Novel {
                title = novelTitle,
                link = shrinkURL(novelUrl) .. statusFmt,
            }
        end)
    end)

    return _novels
end

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local doc = GETDocument(expandURL(chapterURL))
    local content = doc:selectFirst("#main article")
    local p = content:selectFirst(".entry-content")

    WPCommon.cleanupElement(p)
    WPCommon.cleanupPassages(p:select("p"), true)
    WPCommon.cleanupPassages(p:select("div"), true)

    local chTitle = content:selectFirst(".entry-title")
    if chTitle ~= nil then
        p:child(0):before("<h2>" .. chTitle:text() .. "</h2><hr/>")
    end

    return pageOfElem(p)
end

--- @param url string
--- @return string
local function cleanImgUrl(url)
    local found = url:find("?w=")
    if found == nil then
        return url
    end
    return url:sub(0, found - 1)
end

---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
--- Taken from Madara.lua
local function getImgSrc(image_element)
    local origFile = image_element:attr("data-orig-file")
    if origFile ~= "" then return origFile end
    -- Check srcset:
    local srcset = image_element:attr("srcset")
    if srcset ~= "" then
        -- Get the largest image.
        local max_size, max_url = 0, ""
        for url, size in srcset:gmatch("(http.-) (%d+)w") do
            if tonumber(size) > max_size then
                max_size = tonumber(size)
                max_url = url
            end
        end
        return max_url
    end

    -- Default to src (the most likely place to be loaded via script):
    return cleanImgUrl(image_element:attr("src"))
end

--- @param h3Start Element
local function extractDescription(h3Start)
    if h3Start == nil then return "" end

    local description = ""
    local nextElem = h3Start:nextElementSibling()
    while nextElem ~= nil do
        local textContent = nextElem:text():lower()
        if WPCommon.contains(textContent, "table of content") then
            break
        end
        description = description .. nextElem:text() .. "\n\n"
        nextElem = nextElem:nextElementSibling()
    end
    return description
end

--- @param currentEntry Element
local function findChapterTitle(currentEntry)
    currentEntry = currentEntry:previousElementSibling()
    while currentEntry ~= nil do
        local textContent = currentEntry:text():lower()
        if WPCommon.contains(textContent, "table of content") then
            break
        end
        if WPCommon.contains(textContent, "chapter") then
            return currentEntry:text()
        end
        currentEntry = currentEntry:previousElementSibling()
    end
    return nil
end


--- @param list string[]
--- @param str string
--- @return boolean
local function isStringInList(list, str)
    for _, value in pairs(list) do
        if value == str then
            return true
        end
    end
    return false
end

--- @param currentEntry Element
--- @param foundVolumeTitle string[]
local function findVolumeTitle(currentEntry, foundVolumeTitle)
    currentEntry = currentEntry:previousElementSibling()
    while currentEntry ~= nil do
        local textContent = currentEntry:text():lower()
        if WPCommon.contains(textContent, "table of content") then
            break
        end
        if WPCommon.contains(textContent, "volume") then
            local volumeTitle = currentEntry:text()
            -- strip volume title only to "Volume X" part
            local volumeTitle = volumeTitle:match("Volume %d+")
            local volumeTitle = volumeTitle:gsub("Volume ", "Vol. ")
            if not isStringInList(foundVolumeTitle, currentEntry) then
                foundVolumeTitle[#foundVolumeTitle + 1] = volumeTitle
                return volumeTitle
            end
        end
        currentEntry = currentEntry:previousElementSibling()
    end
    return nil
end

--- @param currentEntry Element
local function goUpParent(currentEntry)
    local parent = currentEntry:parent()
    if parent ~= nil then
        if parent:tagName() == "strong" or parent:tagName() == "b" or parent:tagName() == "span" then
            return goUpParent(parent)
        end
        return parent
    end
    return currentEntry
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
    --- Novel page, extract info from it.
    local document = GETDocument(expandURL(novelURL))

    local entryContent = document:selectFirst(".entry-content")
    local jpPostFlair = entryContent:selectFirst(".jp-post-flair")
    if jpPostFlair then jpPostFlair:remove() end

    local novelTitle = document:selectFirst(".entry-title"):text()

    local novelInfo = NovelInfo {
        title = novelTitle,
    }
    local imgComponent = entryContent:selectFirst("img")
    if imgComponent then
        novelInfo:setImageURL(getImgSrc(imgComponent))
    end
    local desc = extractDescription(entryContent:selectFirst("h3"))
    if desc ~= "" then
        novelInfo:setDescription(desc)
    end
    if WPCommon.contains(novelURL, "#shosetsu-status-completed") then
        novelInfo:setStatus(NovelStatus.COMPLETED)
    elseif WPCommon.contains(novelURL, "#shosetsu-status-paused") then
        novelInfo:setStatus(NovelStatus.PAUSED)
    else
        novelInfo:setStatus(NovelStatus.PUBLISHING)
    end

    local _chapters = {}
    local _foundVolumeTitles = {}
    map(entryContent:select("a"), function (v)
        local url = rewriteUrl(v:attr("href"))
        if not WPCommon.contains(url, "nyx-translation.com") then return end
        if WPCommon.contains(url, "?share=") then return end
        local prependEl = goUpParent(v)

        local volumeTextPrepend = ""
        if WPCommon.contains(novelTitle:lower(), "(ln)") then
            local volumeText = findVolumeTitle(prependEl, _foundVolumeTitles)
            if volumeText ~= nil then
                volumeTextPrepend = volumeText .. " "
            end
        end

        local chapterTitle = v:text()
        if not WPCommon.contains(chapterTitle:lower(), "chapter") then
            local prependTextCh = findChapterTitle(prependEl)
            if prependTextCh ~= nil then
                chapterTitle = prependTextCh .. " - " .. chapterTitle
            end
        end
        chapterTitle = chapterTitle:gsub("Chapter ", "Ch. ")
        chapterTitle = volumeTextPrepend .. chapterTitle

        _chapters[#_chapters + 1] = NovelChapter {
            link = shrinkURL(url),
            title = chapterTitle,
            order = #_chapters + 1,
        }
    end)
    novelInfo:setChapters(AsList(_chapters))

    return novelInfo
end

-- Return all properties in a lua table.
return {
    -- Required
    id = 13640,
    name = "Nyx Translation",
    baseURL = baseURL,
    listings = {
        Listing("Novels", false, parseListings),
    }, -- Must have at least one listing
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/NyxTranslation.png",
    hasCloudFlare = false,
    hasSearch = false,
    isSearchIncrementing = false,
    chapterType = ChapterType.HTML,
}
