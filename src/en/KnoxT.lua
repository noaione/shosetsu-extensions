-- {"id":954053,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon");
local baseURL = "https://knoxt.space"

local cssExtras = [[
.epheader {
    text-align: center;
}
.epsubtitle {
    text-align: center;
}
]]


local function startsWith(data, start)
    return data:sub(1, #start) == start
end

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-knoxt%.space", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    if startsWith(url, "/") then
        return baseURL .. url
    end
    return baseURL .. "/" .. url
end

--- @param url string
--- @return string
local function stripWPOptimizer(url)
    -- remove wordpress image optimizer
    -- ex: https://i2.wp.com/knoxt.space/wp-content/uploads/2023/06/I-Just-Want-To-Retire-Quietly.jpeg?resize=370,500
    -- into: https://knoxt.space/wp-content/uploads/2023/06/I-Just-Want-To-Retire-Quietly.jpeg
    
    local wpOpt = "i%d%.wp%.com"
    local wpOptRegex = "https?://" .. wpOpt .. "/(.+)%?.+"
    url = url:gsub(wpOptRegex, "https://%1")
    return url
end

--- @param doc Document
--- @return Novel[]
local function parseListing(doc)
    local listUpdates = doc:selectFirst(".listupd")

    local _novels = {}
    map(listUpdates:select("> article"), function (article)
        local linkTarget = article:selectFirst("a")
        local title = linkTarget:selectFirst(".ntitle"):text()
        local link = shrinkURL(linkTarget:attr("href"))
        local imageUrl = linkTarget:selectFirst("img"):attr("src")

        local novel = Novel {
            title = title,
            link = link,
            imageURL = stripWPOptimizer(imageUrl),
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

    local postBody = doc:selectFirst(".postbody")

    local sectionHead = postBody:selectFirst(".animefull")
    local infoX = sectionHead:selectFirst(".infox")

    local title = infoX:selectFirst(".entry-title"):text()
    local imgThumb = sectionHead:selectFirst(".thumbook"):selectFirst("img"):attr("src")

    local novel = NovelInfo {
        title = title,
        language = "English",
        imageURL = stripWPOptimizer(imgThumb),
    }

    local genreMap = infoX:selectFirst(".genxed")
    novel:setGenres(map(genreMap:children(), function (genre)
        return genre:text()
    end))

    local infoPills = infoX:selectFirst(".spe")
    local _authors = {}
    local _artists = {}
    map(infoPills:children(), function (info)
        local pre = (info:selectFirst("b") or info:selectFirst("strong")):text()
        local data = info:text():gsub("^" .. pre, "")
        -- strip trailing and leading spaces
        data = data:gsub("^%s*(.-)%s*$", "%1")
        if WPCommon.contains(pre, "Author") then
            _authors[#_authors + 1] = data
        elseif WPCommon.contains(pre, "Artist") then
            _artists[#_artists + 1] = data
        elseif WPCommon.contains(pre, "Status") then
            local status = ({
                ["Hiatus"] = NovelStatus.PAUSED,
                ["Ongoing"] = NovelStatus.PUBLISHING,
                ["Completed"] = NovelStatus.COMPLETED,
            })[data]
            print(status, data, novelUrl)
            if status ~= nil then
                novel:setStatus(status)
            end
        end
    end)

    if #_authors > 0 then
        novel:setAuthors(_authors)
    end
    if #_artists > 0 then
        novel:setArtists(_artists)
    end

    local synopsisArea = postBody:selectFirst(".synp")
    if synopsisArea then
        local synopsisText = ""
        map(synopsisArea:selectFirst(".entry-content"):select("p"), function (p)
            synopsisText = synopsisText .. p:text() .. "\n"
        end)
        -- strip last \n
        synopsisText = synopsisText:gsub("\n$", "")
        novel:setDescription(synopsisText)
    end

    if loadChapters then
        -- load chapters
        local chapterList = doc:selectFirst(".eplisterfull")

        local _loadedChapters = {}
        map(chapterList:select("> ul > li"), function (vv)
            local linkData = vv:selectFirst("a")
            local order = tonumber(vv:attr("data-id"))

            local epNum = linkData:selectFirst(".epl-num"):text()
            local epTitle = linkData:selectFirst(".epl-title"):text()
            local published = linkData:selectFirst(".epl-date")

            local aLink = linkData:attr("href")
            local chNov = NovelChapter {
                title = epNum .. " — " .. epTitle,
                link = shrinkURL(aLink),
                order = order
            }
            if published then
                chNov:setRelease(published:text())
            end
            _loadedChapters[#_loadedChapters + 1] = chNov
        end)

        novel:setChapters(AsList(_loadedChapters))
    end
    return novel
end

--- @param chapterUrl string
--- @return any
local function parsePassages(chapterUrl)
    local doc = GETDocument(expandURL(chapterUrl))

    local section = doc:selectFirst(".epwrapper")

    local chapterContainer = section:selectFirst(".epcontent")

    map(chapterContainer:select("> .code-block"), function (v)
        local text = v:text()
        if WPCommon.contains(text, "Advert") then
            v:remove()
        end
    end)
    map(chapterContainer:select("a"), function (v)
        local href = v:attr("href")
        if WPCommon.contains(href, "ko-fi") then
            v:remove()
        end
    end)

    local entryTitle = section:selectFirst(".entry-title")
    local entrySubtitle = section:selectFirst(".entry-subtitle")
    local hrExtra = "<hr/>"
    if entrySubtitle then
        chapterContainer:child(0):before("<h3 class=\"epsubtitle\">" .. entrySubtitle:text() .. "</h3><hr/>")
        hrExtra = ""
    end
    chapterContainer:child(0):before("<h2 class=\"epheader\">" .. entryTitle:text() .. "</h2>" .. hrExtra)

    return pageOfElem(chapterContainer, false, cssExtras)
end

--- @param data table
--- @return Novel[]
local function searchNovel(data)
    local query = data[QUERY]
    local page = data[PAGE]

    local reqUrl = "/page/" .. page .. "/?s=" .. query
    local doc = GETDocument(expandURL(reqUrl))
    return parseListing(doc)
end

--- @param data table
--- @return Novel[]
local function latestNovel(data)
    local page = data[PAGE]

    local reqUrl = "/series/?page=" .. page .. "&status=&type=&order=update"
    local doc = GETDocument(expandURL(reqUrl))
    return parseListing(doc)
end

return {
    id = 954053,
    name = "KnoxT",
    baseURL = baseURL,

    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/KnoxT.png",
    hasSearch = true,
    hasCloudFlare = false,

    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Latest", true, latestNovel)
    },

    getPassage = parsePassages,
    parseNovel = getAndParseNovel,

    shrinkURL = shrinkURL,
    expandURL = expandURL,

    startIndex = 1,
    hasSearch = true,
    isSearchIncrementing = true,
    search = searchNovel,
}
