-- {"id":28903,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.3"]}

local baseURL = "https://glucosetl.wordpress.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-glucosetl%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local postBody = doc:selectFirst("div.wp-site-blocks")
    local content = postBody:selectFirst("main > .entry-content")

    WPCommon.cleanupElement(content)

    map(content:children(), function (v)
        if WPCommon.cleanupElement(v) then return end
        local className = v:attr("class")
        local tagName = v:tagName()
        if tagName == "div" and WPCommon.contains(className, "wp-block-buttons") then
            v:remove()
        end
    end)

    -- add title
    local postTitle = postBody:selectFirst(".wp-block-post-title")
    if postTitle then
        local title = postTitle:text()
        content:child(0):before("<h2>" .. title .. "</h2><hr/>")
    end

    return content
end

--- @param elem Element|nil
--- @return Element|nil
local function findImageNode(elem)
    if not elem then
        return nil
    end

    local nextSib = elem:nextElementSibling()
    if nextSib then
        local className = nextSib:attr("class")
        if WPCommon.contains(className, "wp-block-image") then
            local imgNode = nextSib:selectFirst("img")
            if imgNode then
                return imgNode
            end
        end
        local tagName = nextSib:tagName()
        if tagName == "h2" and WPCommon.contains(className, "wp-block-heading") then
            -- we reach the next heading, stop!
            return nil
        end
        return findImageNode(nextSib)
    end
    return nil
end

--- @param elem Element|nil
--- @return Element|nil
local function findImageNodeAlt(elem)
    local parent = elem:parent()
    if parent == nil then
        return nil
    end

    local childIndex = parent:elementSiblingIndex()
    local parentTwo = parent:parent()
    if parentTwo == nil then
        return nil
    end

    local nextSib = parentTwo:nextElementSibling()
    if nextSib == nil then
        return nil
    end

    local demFigures = nextSib:select("figure")
    if demFigures:size() == 0 then
        return nil
    end

    local figures = demFigures:get(childIndex)
    if figures then
        local imgNode = figures:selectFirst("img")
        if imgNode then
            return imgNode
        end
    end
    return nil
end

--- @param text string
--- @return table
local function stripAndExtractStatus(text)
    -- The Neat and Pretty Girl at My New School Is a Childhood Friend of Mine Who I Thought Was a Boy (LN)
    -- I Know That After School, The Saint is More Than Just Noble (Completed)
    -- The Story of Two Engaged Childhood Friends Trying to Fall in Love (Sporadic)
    -- The Detective Is Already Dead (Dropped)

    -- Remove stuff with Completed, Sporadic, or Dropped
    local status = text:match("%((.-)%)$")

    if status then
        if WPCommon.contains(status:lower(), "completed") or WPCommon.contains(status:lower(), "dropped") or WPCommon.contains(status:lower(), "sporadic") then
            -- return title, status
            return text:gsub(" %((.-)%)$", ""), status
        end
    end
    return text, nil
end

--- @param doc Document
local function parseListings(doc)
    local postBody = doc:selectFirst("main")
    local content = postBody:selectFirst(".entry-content")
    WPCommon.cleanupElement(content)

    return mapNotNil(content:select("p a"), function (v)
        local url = v:attr("href")
        if not WPCommon.contains(url, "glucosetl.wordpress.com") then
            return nil
        end
        local _parent = v:parent()
        if not _parent then
            return nil
        end

        local text, status = stripAndExtractStatus(v:text())
        local url = shrinkURL(url)
        if status then
            url = url .. "#shosetsu-status=" .. status:lower()
        end
        local _temp = Novel {
            title = text,
            link = url
        }
        local imgNode = findImageNode(_parent)

        if imgNode then
            _temp:setImageURL(imgNode:attr("src"))
        else -- try another method
            imgNode = findImageNodeAlt(_parent)
            if imgNode then
                _temp:setImageURL(imgNode:attr("src"))
            end
        end
        return _temp
    end)
end

--- @param elem Element
--- @return string|nil
local function findVolumeText(elem)
    if not elem then
        return nil
    end

    local prevSib = elem:previousElementSibling()
    if prevSib then
        local text = prevSib:text()
        local tagName = prevSib:tagName()
        if WPCommon.contains(tagName, "h") or tagName == "p" then
            if WPCommon.contains(text, "Volume") then
                -- for example: Volume 1
                -- Volume 1 (some random shit)
                -- we only want to get the volume number
                local volume = text:match("Volume (%d+)")
                if volume then
                    return "Volume " .. volume
                end
            end
        end
        return findVolumeText(prevSib)
    end
    return nil
end


--- @param doc Document
--- @param loadChapters boolean
--- @param novelUrl string
local function parseNovelInfo(doc, loadChapters, novelUrl)
    local postBody = doc:selectFirst("div.wp-site-blocks")
    local content = postBody:selectFirst("main > .entry-content")
    local postTitle = postBody:selectFirst(".wp-block-post-title"):text()

    WPCommon.cleanupElement(content)

    local info = NovelInfo {
        title = postTitle,
        status = NovelStatus.PUBLISHING,
    }

    local imageTarget = content:selectFirst("img")
    if imageTarget then
        info:setImageURL(imageTarget:attr("src"))
    end

    if WPCommon.contains("#shosetsu-status=completed") then
        info:setStatus(NovelStatus.COMPLETED)
    elseif WPCommon.contains("#shosetsu-status=dropped") then
        info:setStatus(NovelStatus.PAUSED)
    end

    if loadChapters then
        local chapters = {}
        map(content:select("p a"), function (v)
            local url = v:attr("href")
            if not WPCommon.contains(url, "glucosetl.wordpress.com") then
                return nil
            end
            local tempText = v:text()
            if WPCommon.contains(tempText, "PDF") then return nil end
            -- we want to get the heading text
            local _parent = v:parent()
            if not _parent then
                return nil
            end
            local volText = findVolumeText(_parent)
            if volText then
                tempText = volText .. " " .. tempText
            end
            local _temp = NovelChapter {
                order = #chapters + 1,
                title = tempText,
                link = shrinkURL(url)
            }
            chapters[#chapters + 1] = _temp
        end)
        info:setChapters(AsList(chapters))
    end
    return info
end

return {
    id = 28903,
    name = "Glucose Translations",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/GlucoseTL.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function ()
            return parseListings(GETDocument("https://glucosetl.wordpress.com/translations/"))
        end),
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(baseURL .. novelURL)
        return parseNovelInfo(doc, loadChapters, novelURL)
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
