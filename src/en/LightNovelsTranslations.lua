-- {"id":26375,"ver":"0.3.2","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://lightnovelstranslations.com"
local settings = {}

local SORT_BY_FILTER_EXT = { "Ascending", "Descending", "Chapters", "Highest Rated", "Most Liked", "Most Recent" }
local NOVEL_TYPE_FITLER_EXT = { "All", "Original", "Translated" }
local NOVEL_STATUS_FILTER_EXT = { "All", "Completed", "Ongoing" }
local SORT_BY_FILTER_KEY = 2
local NOVEL_TYPE_FITLER_KEY = 3
local NOVEL_STATUS_FILTER_KEY = 4
local CW_GORE_KEY = 5
local CW_SEXUAL_CONTENT_KEY = 6

local GENRES = {
    "Action: 121",
    "Adventure: 122",
    "Anti-Hero Lead: 145",
    "Comedy: 123",
    "Different World (Isekai): 146",
    "Drama: 148",
    "Dungeon: 147",
    "Ecchi: 177",
    "Fantasy: 153",
    "Female Lead: 150",
    "Gender Bender: 151",
    "Harem: 125",
    "Historical: 154",
    "Horror: 156",
    "LitRPG: 157",
    "Magic: 159",
    "Mecha: 160",
    "Mystery: 161",
    "Non-Human Lead: 162",
    "OP Main Lead: 163",
    "Post-Apocalyptic: 164",
    "Psychological: 165",
    "Reincarnation: 166",
    "Revenge: 167",
    "Romance: 126",
    "Ruling Class: 169",
    "School Life: 127",
    "Science Fiction: 170",
    "Slice of Life: 172",
    "Sports: 171",
    "Strategy: 168",
    "Supernatural: 128",
    "Tragedy: 158",
    "Virtual Reality: 155",
    "War and Military: 152",
}

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-lightnovelstranslations.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

local function startsWith(str, start)
    return str:sub(1, #start) == start
end

--- @param str string
--- @param pattern string
local function contains(str, pattern)
    return str:find(pattern, 0, true) and true or false
end

local function createSearchString(tbl)
    local query = tbl[QUERY]
    local page = tbl[PAGE]
    local sortBy = tbl[SORT_BY_FILTER_KEY]
    local typeBy = tbl[NOVEL_TYPE_FITLER_KEY]
    local statusBy = tbl[NOVEL_STATUS_FILTER_KEY]

    local url = baseURL .. "/read/page/" .. page .. "/"
    if sortBy ~= nil then
        url = url .. "?sort=" .. ({
            [0] = "asc",
            [1] = "desc",
            [2] = "chapters",
            [3] = "highest-rated",
            [4] = "most-liked",
            [5] = "most-recent"
        })[sortBy]
    else
        url = url .. "?sort=most-recent"
    end
    if typeBy ~= nil then
        url = url .. "&type=" .. ({
            [0] = "all",
            [1] = "original",
            [2] = "translated"
        })[typeBy]
    else
        url = url .. "&type=all"
    end
    if statusBy ~= nil then
        url = url .. "&status=" .. ({
            [0] = "all",
            [1] = "completed",
            [2] = "ongoing"
        })[statusBy]
    else
        url = url .. "&status=all"
    end
    return url
end


---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
--- Taken from Madara.lua
local function getImgSrc(image_element)
	-- Check data-srcset:
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
	return image_element:attr("src")
end

--- @param doc Document
--- @return Novel[]
local function parseListing(doc)
    local section = doc:selectFirst("section.read_list-story")
    local wrapReadListStory = section:selectFirst("div.wrap_read_list-story")

    local _novels = {}
    map(wrapReadListStory:select("> .read_list-story-item"), function (v)
        local imgThumb = v:selectFirst(".item_thumb"):selectFirst("img")
        local wrapInner = v:selectFirst(".wrap_item_content")
        local titleElem = wrapInner:selectFirst(".read_list-story-item--title"):selectFirst("a")

        local novel = Novel {
            title = titleElem:text(),
            link = shrinkURL(titleElem:attr("href")),
        }
        if imgThumb then
            novel:setImageURL(getImgSrc(imgThumb))
        end
        _novels[#_novels + 1] = novel
    end)
    return _novels
end

--- @param data table
--- @param inc int
--- @return Novel[]
local function latestNovel(data)
    local doc = GETDocument(baseURL .. "/read/page/" .. data[PAGE] .. "/")
    return parseListing(doc)
end

local function doSearch(data)
    local urlReq = createSearchString(data)
    local searchString = data[QUERY]
    local cwGore = data[CW_GORE_KEY]
    local cwSex = data[CW_SEXUAL_CONTENT_KEY]
    local builder = FormBodyBuilder()
    builder:add("field-search", searchString)
    if cwGore == 1 then
        builder:add("content_warning_search_value[]", "139")
    elseif cwGore == 2 then
        builder:add("exclude_content_warning[]", "139")
    end
    if cwSex == 1 then
        builder:add("content_warning_search_value[]", "138")
    elseif cwSex == 2 then
        builder:add("exclude_content_warning[]", "138")
    end
    for _, v in ipairs(GENRES) do
        local key, value = v:match("^(.-):%s*(.-)$")
        local aVk = tonumber(value)
        if data[aVk] == 1 then
            builder:add("tag_name[]", key)
        elseif data[aVk] == 2 then
            builder:add("exclude_tag_name[]", key)
        end
    end
    builder:add("submit", "")

    doc = RequestDocument(
        POST(
            urlReq,
            nil,
            builder:build()
        )
    )
    return parseListing(doc)
end

local function getAndParseNovel(novelUrl, loadChapters)
    local doc = GETDocument(expandURL(novelUrl))

    local section = doc:selectFirst("section.actual-read-section")
    local title = section:selectFirst(".novel_title"):text()

    local imgEl = section:selectFirst(".novel-image"):selectFirst("img")

    local novel = NovelInfo {
        title = title,
        language = "English"
    }
    if imgEl then
        novel:setImageURL(getImgSrc(imgEl))
    end

    local novelStatus = section:selectFirst(".novel_status"):text()
    if novelStatus == "Completed" then
        novel:setStatus(NovelStatus.COMPLETED)
    elseif novelStatus == "Ongoing" then
        novel:setStatus(NovelStatus.PUBLISHING)
    end

    local aboutTab = section:selectFirst("div#about"):selectFirst(".novel_text")
    local textDesc = ""
    map(aboutTab:select("> p"), function (v)
        textDesc = textDesc .. v:text() .. "\n"
    end)
    textDesc = textDesc:gsub("\n+$", "")
    novel:setDescription(textDesc)

    local novelGenres = section:selectFirst(".novel_tags_item")
    novel:setGenres(map(novelGenres:select("> span"), function (v)
        return v:text()
    end))

    local novelTags = {}
    local novelAuthors = {}
    map(section:selectFirst(".novel_detail_info"):selectFirst("> ul"):select("> li"), function (ev)
        local text = ev:text()
        if startsWith(text, "Author:") then
            novelAuthors[#novelAuthors + 1] = text:sub(8)
        end
        if startsWith("Translator:") then
            novelTags[#novelTags + 1] = text
        end
        if startsWith("Editor:") then
            novelTags[#novelTags + 1] = text
        end
    end)
    novel:setAuthors(novelAuthors)
    novel:setTags(novelTags)

    if loadChapters then
        -- load chapters
        local docChapter = GETDocument(expandURL(novelUrl) .. "?tab=table_contents")
        local chapterList = docChapter:selectFirst(".novel_list_chapter_content")
        local _loadedChapters = {}
        map(chapterList:select("> .novel_list_chapter_content"), function (v)
            map(v:select(".accordition_item_content > ul > .chapter-item"), function (vv)
                local className = vv:attr("class")
                if not contains(className, "unlock") then -- locked chapter bye bye
                    return
                end
                local aLink = vv:selectFirst("a")
                local chNov = NovelChapter {
                    title = aLink:text(),
                    link = shrinkURL(aLink:attr("href")),
                    order = #_loadedChapters + 1
                }
                _loadedChapters[#_loadedChapters + 1] = chNov
            end)
        end)
        novel:setChapters(AsList(_loadedChapters))
    end
    return novel
end

local function parsePassages(chapterUrl)
    local doc = GETDocument(expandURL(chapterUrl))

    local chapterContainer = doc:selectFirst(".text_story")

    map(chapterContainer:select("p"), function (v)
        local text = v:text():lower()
        if contains(text, "previous_page") then
            v:remove()
            return
        end
        if contains(text, "next_page") then
            v:remove()
            return
        end
    end)
    map(chapterContainer:select("> div > div"), function (v)
        if contains(v:attr("class"), "ads_content") then
            v:remove()
        end
    end)
    return pageOfElements(chapterContainer)
end

return {
    id = 26375,
    name = "Light Novels Translations",
    baseURL = baseURL,

    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/LightNovelsTranslations.png",
    hasSearch = true,
    hasCloudFlare = true,

    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", true, latestNovel)
    },

    searchFilters = {
        DropdownFilter(SORT_BY_FILTER_KEY, "Sort By", SORT_BY_FILTER_EXT),
        DropdownFilter(NOVEL_TYPE_FITLER_KEY, "Novel Type", NOVEL_TYPE_FITLER_EXT),
        DropdownFilter(NOVEL_STATUS_FILTER_KEY, "Novel Status", NOVEL_STATUS_FILTER_EXT),
		FilterGroup("Content Warning", {
			TriStateFilter(CW_GORE_KEY, "Gore"),
			TriStateFilter(CW_SEXUAL_CONTENT_KEY, "Sexual Content"),
		}),
        FilterGroup("Genres", map(GENRES, function (v)
            local key, value = v:match("^(.-):%s*(.-)$")
            return TriStateFilter(tonumber(value), key)
        end)),
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
