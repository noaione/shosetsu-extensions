-- {"id":4302,"ver":"2.0.4","libVer":"1.0.0","author":"N4O","dep":["dkjson>=1.0.1","Multipartd>=1.0.0"]}

local json = Require("dkjson");
local Multipartd = Require("Multipartd");

local baseURL = "https://storyseedling.com"

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

local encode = Require("url").encode

local text = function(v)
	return v:text()
end

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

local function getPassage(chapterURL)
	local chap = GETDocument(expandURL(rewriteChapterUrl(chapterURL))):selectFirst("main")

	local title = chap:selectFirst("h1"):text()
	chap = chap:selectFirst(".prose")
	chap:child(0):before("<h1>" .. title .. "</h1>")
	-- Remove empty <p> tags
	local toRemove = {}
	chap:traverse(NodeVisitor(function(v)
		if v:tagName() == "p" and v:text() == "" then
			toRemove[#toRemove+1] = v
		end
		if v:hasAttr("border") then
			v:removeAttr("border")
		end
	end, nil, true))
	for _,v in pairs(toRemove) do
		v:remove()
	end
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

	if loadChapters then
		local baseSelector = chapterSelector:selectFirst('div[x-show.transition.in.opacity.duration.600]')
		local selectChapters = baseSelector:select("a[up-deprecated]")
		local chapterSize = selectChapters:size()
		-- Start from last chapter to first since website shows it in reverse order
		-- This is to keep the order consistent with other sources
		local _chapters = {}
		for i = chapterSize - 1, 0, -1 do
			local v = selectChapters:get(i)
			-- This is to ignore the premium chapter, those have a lock icon in their anchor.
			local firstPremChapter = v:selectFirst("svg.feather-droplet")
			if firstPremChapter == nil then
				local divBase = v:selectFirst("div")
				_chapters[#_chapters + 1] = NovelChapter {
					order = #_chapters,
					title = divBase:selectFirst(".truncate"):text(),
					link = shrinkURL(v:attr("href")),
					release = divBase:selectFirst("small.text-xs"):text()
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
			imageURL = v.bigThumbnail,
		}
	end)
end

local function getSearch(data)
	local query = data[QUERY]
	local page = data[PAGE]
	local orderBy = data[ORDER_BY_FILTER]

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

	formBuilder:add("post", "098dc92952")
	formBuilder:add("action", "fetch_browse")

	-- for media type, cut off the first two dashes
	local headers = HeadersBuilder()
	headers:add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0")
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
