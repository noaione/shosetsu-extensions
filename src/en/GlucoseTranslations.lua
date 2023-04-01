-- {"id":28903,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

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

        local _temp = Novel {
            title = v:text(),
            link = shrinkURL(url)
        }
        local imgNode = findImageNode(_parent)

        if imgNode then
            _temp:setImageURL(imgNode:attr("src"))
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
local function parseNovelInfo(doc, loadChapters)
    local postBody = doc:selectFirst("div.wp-site-blocks")
    local content = postBody:selectFirst("main > .entry-content")
    local postTitle = postBody:selectFirst(".wp-block-post-title"):text()

    WPCommon.cleanupElement(content)

    local info = NovelInfo {
        title = postTitle,
    }

    local imageTarget = content:selectFirst("img")
    if imageTarget then
        info:setImageURL(imageTarget:attr("src"))
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
        Listing("Ongoing", false, function ()
            return parseListings(GETDocument("https://glucosetl.wordpress.com/ongoing-translations/"))
        end),
        Listing("Completed", false, function ()
            return parseListings(GETDocument("https://glucosetl.wordpress.com/completed-translations/"))
        end),
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(baseURL .. novelURL)
        return parseNovelInfo(doc, loadChapters)
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
