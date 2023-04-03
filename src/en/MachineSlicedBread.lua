-- {"id":811702,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://machineslicedbread.xyz"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-www%.machineslicedbread%.xyz", ""):gsub("^.-machineslicedbread%.xyz", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
    local doc = GETDocument(expandURL(chapterURL))
    -- check if protected
    local prot = doc:selectFirst("form.post-password-form")
    if prot then
        error("This chapter is locked!")
    end

    -- process
    local p = doc:selectFirst(".entry-content")

    WPCommon.cleanupElement(p)
    local stopRemovingToc = false
    map(p:select("p a"), function (v)
        if stopRemovingToc then return end
        local parent = v:parent()
        if parent then
            if WPCommon.isTocRelated(parent:text()) then
                stopRemovingToc = true
                parent:remove()
            end
        end
    end)
    local textBoxA = p:selectFirst("#textbox")
    if textBoxA then textBoxA:remove() end
    local textBoxB = p:selectFirst("#textbox")
    if textBoxB then textBoxB:remove() end

    local entryTitle = doc:selectFirst(".entry-title")
    if entryTitle then
        local title = entryTitle:text()
        if title then
            p:child(0):before("<h2>" .. title .. "</h2><hr/>")
        end
    end

    return pageOfElem(p)
end

--- @param v Element
--- @return table|nil
local function iterNovelChapter(v)
    local href = v:attr("href")
    local text = v:text()
    if not WPCommon.contains(href, "machineslicedbread") then return nil end

    if WPCommon.contains(text:lower(), "direct link") then
        -- previous elem is chapter title
        local prevEl = v:previousElementSibling()
        if prevEl then
            text = prevEl:text()
        end
    end

    -- locked chapter
    if WPCommon.contains(text:lower(), "(locked)") then return nil end

    return {
        t = text,
        u = shrinkURL(href)
    }
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
    local doc = GETDocument(expandURL(novelURL))

    local entryContent = doc:selectFirst("div.entry-content")

    local _novelInfo = NovelInfo {
        title = doc:selectFirst(".entry-title"):text(),
    }
    local imgEl = entryContent:selectFirst("img")
    if imgEl then
        _novelInfo:setImageURL(imgEl:attr("src"))
    end
    if WPCommon.contains(novelURL, "#shosetsu-status-complete") then
        _novelInfo:setStatus(NovelStatus.COMPLETED)
    elseif WPCommon.contains(novelURL, "#shosetsu-status-dropped") then
        _novelInfo:setStatus(NovelStatus.PAUSED)
    else
        _novelInfo:setStatus(NovelStatus.PUBLISHING)
    end

    -- load chapters
    local _Chapters = {}
    map(entryContent:select("p a"), function (v)
        local result = iterNovelChapter(v)
        if result then
            _Chapters[#_Chapters + 1] = NovelChapter {
                title = result.t,
                link = result.u,
                order = #_Chapters + 1,
            }
        end
    end)
    map(entryContent:select("li a"), function (v)
        local result = iterNovelChapter(v)
        if result then
            _Chapters[#_Chapters + 1] = NovelChapter {
                title = result.t,
                link = result.u,
                order = #_Chapters + 1,
            }
        end
    end)
    map(entryContent:select("div a"), function (v)
        local result = iterNovelChapter(v)
        if result then
            _Chapters[#_Chapters + 1] = NovelChapter {
                title = result.t,
                link = result.u,
                order = #_Chapters + 1,
            }
        end
    end)

    _novelInfo:setChapters(AsList(_Chapters))
    return _novelInfo
end

--- @param headEl Element
--- @param hitElement string
local function _getAllNovelsUntil(headEl, hitElement)
    local _novels = {}
    local htmlString = ""
    local nextEl = headEl:nextElementSibling()
    while nextEl and nextEl:tagName() ~= hitElement do
        htmlString = htmlString .. nextEl:html()
        nextEl = nextEl:nextElementSibling()
    end
    local allElement = Document(htmlString)
    map(allElement:select("li"), function (v)
        local novelURL = v:selectFirst("a"):attr("href")
        local novelTitle = v:selectFirst("a"):text()
        if WPCommon.contains(novelURL, "machineslicedbread") then
            _novels[#_novels + 1] = {
                t = novelTitle,
                u = shrinkURL(novelURL)
            }
        end
    end)
    return _novels
end

local function parseListings(isOriginal)
    local doc = GETDocument(baseURL)

    local entryContent = doc:selectFirst("div.entry-content")

    local _listings = {}
    map(entryContent:select("> h2"), function (head)
        if isOriginal then
            -- process original novel
            for _, novel in ipairs(_getAllNovelsUntil(head, "hr")) do
                _listings[#_listings + 1] = Novel {
                    title = novel.t,
                    link = novel.u,
                }
            end
        else
            local h2Text = head:text()
            if WPCommon.contains(h2Text, "Original") then return end
            for _, novel in ipairs(_getAllNovelsUntil(head, "hr")) do
                local novelUrl = novel.u
                -- magical status detection
                if WPCommon.contains(h2Text, "Complete") then
                    novelUrl = novelUrl .. "#shosetsu-status-complete"
                end
                if WPCommon.contains(h2Text, "Hiatus") then
                    novelUrl = novelUrl .. "#shosetsu-status-dropped"
                end
                _listings[#_listings + 1] = Novel {
                    title = novel.t,
                    link = novelUrl,
                }
            end
        end
    end)
    return _listings
end

return {
    id = 811702,
    name = "Machine Sliced Bread",
    baseURL = baseURL,

    -- Optional values to change
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/MachineSlicedBread.png",
    hasCloudFlare = false,
    hasSearch = false,

    -- Must have at least one value
    listings = {
        Listing("Translated Novels", false, function()
            return parseListings(false)
        end),
        Listing("Original Novels", false, function()
            return parseListings(true)
        end)
    },

    -- Default functions that have to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
