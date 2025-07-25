-- {"id":28903,"ver":"0.2.1","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.3"]}

local baseURL = "https://glucosetl.xyz"

local WPCommon = Require("WPCommon")

local function startsWith(data, start)
    return data:sub(1, #start) == start
end


--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-glucosetl%.xyz", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

--- @param content Document
--- @return boolean
local function isAnubisPage(content)
    local images = content:selectFirst("img")
    ---@diagnostic disable-next-line: unnecessary-if
    -- get the src attribute of the first image
    if images and images:attr("src") then
        local src = images:attr("src")
        if WPCommon.contains(src, ".within-website") then
            return true
        end
    end

    local title = content:selectFirst("h1#title")
    if title and WPCommon.contains(title:text(), "Making sure you're not a bot") then
        return true
    end
    
    return false
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    if isAnubisPage(doc) then
        -- throw error
        error("Anubis bot protection detected. Please view the page in webview and wait for it to complete")
    end
    local postBody = doc:selectFirst("div.flex.gap-10 > div.items-center.bg-black")

    -- add title
    local postTitle = doc:selectFirst("div.flex.gap-10 > .text-2xl")
    if postTitle then
        local title = postTitle:text()
        postBody:child(0):before("<h2>" .. title .. "</h2><hr/>")
    end

    -- find all image source and replace sz=w1000 with sz=s0
    map(postBody:select("img"), function (img)
        local src = img:attr("src")
        if src and WPCommon.contains(src, "sz=w1000") then
            img:attr("src", src:gsub("sz=w1000", "sz=s0"))
        end
    end)

    return postBody
end

--- @param doc Document
local function parseListings(doc)
    if isAnubisPage(doc) then
        -- throw error
        error("Anubis bot protection detected. Please view the page in webview and wait for it to complete")
    end

    local _listings = {}
    map(doc:select("a.foreground.justify-center"), function (elem)
        local href = elem:attr("href")
        if startsWith(href, "/translations/") then
            print("Found translation: " .. href)
            local image = elem:selectFirst("img")

            local groupElem = elem:select("div > div")
            local title = groupElem:get(0):text()
            local status = groupElem:get(2)

            local novel = Novel {
                title = title,
                link = shrinkURL(href),
            }
            if image and image:attr("src") then
                novel:setImageURL(expandURL(image:attr("src")))
            end
            if status then
                local statusText = status:text()
                -- match the status text
                local lowercaseStatus = statusText:lower()
                if WPCommon.contains(lowercaseStatus, "completed") then
                    novel:setLink(shrinkURL(href .. "#shosetsu-status=completed"))
                elseif WPCommon.contains(lowercaseStatus, "ongoing") then
                    novel:setLink(shrinkURL(href .. "#shosetsu-status=ongoing"))
                elseif WPCommon.contains(lowercaseStatus, "dropped") then
                    novel:setLink(shrinkURL(href .. "#shosetsu-status=dropped"))
                end
            end

            _listings[#_listings + 1] = novel
        end
    end)
    return _listings
end

--- @param volumeUrl string
local function queryVolumeChapters(volumeUrl)
    print("Requesting volumes: " .. volumeUrl)
    local doc = GETDocument(expandURL(volumeUrl))

    local _links = {}
    map(doc:select(".foreground > .flex > div.flex > a.link[href]"), function (chapter)
        local path = chapter:attr("href")
        local volumeTitle = chapter:text()
        -- combine volumeUrl with path
        -- remove the first text before slash
        local slashIndex = path:find("/", 2)

        local fullPath = volumeUrl .. "/" .. path
        if slashIndex then
            fullPath = volumeUrl .. "/" .. path:sub(slashIndex + 1)
        end

        _links[#_links + 1] = {
            title = volumeTitle,
            link = shrinkURL(fullPath),
        }
    end)

    print("Found " .. #_links .. " chapters in volume: " .. volumeUrl)
    return _links
end

--- @param doc Document
--- @param loadChapters boolean
--- @param novelUrl string
local function parseNovelInfo(doc, loadChapters, novelUrl)
    local topArea = doc:selectFirst(".container > .foreground.rounded-lg")
    local title = topArea:selectFirst("div.text-4xl")

    local info = NovelInfo {
        title = title:text(),
        status = NovelStatus.PUBLISHING,
    }

    local imageTarget = topArea:selectFirst("img")
    if imageTarget then
        info:setImageURL(expandURL(imageTarget:attr("src")))
    end

    if WPCommon.contains(novelUrl, "#shosetsu-status=completed") then
        info:setStatus(NovelStatus.COMPLETED)
    elseif WPCommon.contains(novelUrl, "#shosetsu-status=dropped") then
        info:setStatus(NovelStatus.PAUSED)
    end

    if loadChapters then
        local _chapters_temp = {}
        map(doc:select("a.foreground.flex"), function (v)
            local url = v:attr("href")
            local volumeTitle = v:text()
            if not startsWith(url, "/") then
                url = '/translations/' .. url
            end

            local allLinks = queryVolumeChapters(url)
            -- if no links were found, skip
            if #allLinks == 0 then
                return
            end

            -- reverse the order of links
            local reversedLinks = {}
            for i = #allLinks, 1, -1 do
                reversedLinks[#reversedLinks + 1] = allLinks[i]
            end

            for _, link in ipairs(reversedLinks) do
                local _temp = {
                    title = volumeTitle .. ': ' .. link.title,
                    link = link.link,
                }
                _chapters_temp[#_chapters_temp + 1] = _temp
            end
            -- local _temp = NovelChapter {
            --     order = #chapters + 1,
            --     title = tempText,
            --     link = shrinkURL(url)
            -- }
            -- chapters[#chapters + 1] = _temp
        end)

        -- reverse the order of chapters
        local chapters = {}
        for i = #_chapters_temp, 1, -1 do
            local temp = _chapters_temp[i]
            local _temp = NovelChapter {
                order = #chapters + 1,
                title = temp.title,
                link = temp.link,
            }
            chapters[#chapters + 1] = _temp
        end
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
            return parseListings(GETDocument("https://glucosetl.xyz/translations"))
        end),
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(baseURL .. novelURL)
        if isAnubisPage(doc) then
            -- throw error
            error("Anubis bot protection detected. Please view the page in webview and wait for it to complete")
        end
        return parseNovelInfo(doc, loadChapters, novelURL)
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
