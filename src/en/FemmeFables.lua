-- {"id":335754,"ver":"0.1.3","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://femmefables.wordpress.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-femmefables%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#content article")
    local p = content:selectFirst(".post-content")

    WPCommon.cleanupElement(p)

    local wordads = content:selectFirst(".wordads-ad-wrapper")
    if wordads then
        wordads:remove()
    end

    local allElements = p:select("> p")
    map(allElements, function (v)
        local textContent = v:text()
        if textContent:len() > 100 then
            -- let's actually check the inner <a> tag
            map(allElements:select("a"), function (alink)
                local ahref = alink:attr("href")
                if ahref:find("femmefables.wordpress.com", 0, true) then
                    alink:remove()
                    return
                end
            end)
        end
    end)

    local postTitle = content:selectFirst(".post-title")
    if postTitle then
        local postTitleText = postTitle:text()
        if postTitleText then
            p:prepend("<h2>" .. postTitleText .. "</h2><hr/>")
        end
    end

    return p
end

return {
    id = 335754,
    name = "Femme Fables",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/FemmeFables.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, function(data)
            local doc = GETDocument(baseURL)
            -- desktop version
            local primaryMenu = doc:selectFirst("#primary-menu")
            local _novels = {}
            map(primaryMenu:select("> li"), function (v)
                local aLink = v:selectFirst("> a")
                local title = aLink:text()
                local url = shrinkURL(aLink:attr("href"))

                _novels[#_novels + 1] = Novel {
                    title = title,
                    link = url
                }
            end)

            return _novels
        end)
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(baseURL .. novelURL)
        local baseArticles = doc:selectFirst("article")
        local content = baseArticles:selectFirst(".post-content")

        local info = NovelInfo {
            title = baseArticles:selectFirst(".entry-title"):text(),
        }

        local imageTarget = doc:selectFirst(".featured-media > img")
        if imageTarget then
            info:setImageURL(imageTarget:attr("src"))
        end

        local descBuild = ""
        local descTarget = content:select("> p")
        map(descTarget, function (desc)
            local content = desc:text()
            descBuild = descBuild .. content .. "\n\n"
        end)

        if descBuild then
            -- strip
            descBuild = descBuild:gsub("^%s*(.-)%s*$", "%1")
            info:setDescription(descBuild)
        end

        if loadChapters then
            info:setChapters(AsList(mapNotNil(content:select("ul li a"), function (v, i)
                local chUrl = v:attr("href")
                return (chUrl:find("femmefables.wordpress.com", 0, true)) and
                    NovelChapter {
                        order = i,
                        title = v:text(),
                        link = shrinkURL(chUrl)
                    }
            end)))
        end

        return info
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
