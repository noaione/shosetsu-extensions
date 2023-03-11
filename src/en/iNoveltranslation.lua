-- {"id":3239,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["MDLua>=1.0.0","dkjson>=1.0.1"]}

local mdRender = Require("MDLua").render
local json = Require("dkjson");

local baseURL = "https://inoveltranslation.com"
local baseAPIURL = "https://api.inoveltranslation.com"
local placeholderImage = "https://inoveltranslation.com/placeholder.png"

local function markdownToHTML(markdown)
	local html, err = mdRender(markdown)
	if err then
		error(err)
	end
	return Document(html)
end

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-inoveltranslation%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

--- @param url string
--- @return string
local function expandAPIURL(url)
	return baseAPIURL .. url
end

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	local doc = GETDocument(expandAPIURL(chapterURL))
	local docContent = json.decode(doc:text())

	--- @type string
	local chTitle = docContent.title
	local chContent = markdownToHTML(docContent.content):selectFirst("body")
	if chTitle then
		chContent:child(0):before("<h2>" .. chTitle .. "</h2><hr/>")
	end
	local notes = docContent.notes
	-- total child

	if notes then
		chContent:lastElementSibling():after("<hr/><h2>Notes</h2>" .. markdownToHTML(notes):selectFirst("body"):html())
	end
	return pageOfElem(chContent)
end

local function getCoverOrFallback(coverMeta)
	local cover = placeholderImage
	if coverMeta ~= nil then
		-- https://api.inoveltranslation.com/image/TheEmperorIsMyBrother'sBestFriend-2222.png
		local coverFilename = coverMeta.filename
		if coverFilename then
			cover = "https://api.inoveltranslation.com/image/" .. coverFilename
		end
	end
	return cover
end

local function makeChapterTitle(chapterMeta)
	-- chapterMeta {
	-- 	slug : str
	-- 	chapter : int
	-- 	volume ?: nullable/int
	-- 	title ?; nullable/str
	-- 	tierId ?: nullable/int
	-- 	id : int
	-- }
	-- format:
	-- Vol. XX Ch. XX: Chapter Title
	-- Vol. XX Ch. XX
	-- Ch. XX
	-- Ch. XX: Chapter Title

	local chapterTitle = ""
	if chapterMeta.volume ~= nil then
		chapterTitle = chapterTitle .. "Vol. " .. chapterMeta.volume .. " "
	end
	chapterTitle = chapterTitle .. "Ch. " .. chapterMeta.chapter
	if chapterMeta.title ~= nil then
		chapterTitle = chapterTitle .. " - " .. chapterMeta.title
	end
	return chapterTitle
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
	local doc = GETDocument(expandAPIURL(novelURL))
	local contents = json.decode(doc:text())
	local novel = NovelInfo {
		title = contents.title,
		imageURL = getCoverOrFallback(contents.cover),
		description = markdownToHTML(contents.description):selectFirst("body"),
	}
	local authors = contents.author
	local genres = contents.genres

	if authors ~= nil then
		local authorPass = { authors.name }
		novel:setAuthors(authorPass)
	end
	if genres ~= nil then
		novel:setGenres(map(genres, function (v)
			return v.name
		end))
	end
	-- staff as tags
	local staff = contents.staff
	if staff ~= nil then
		novel:setTags(map(staff, function (v)
			return v.job .. ": " .. v.username
		end))
	end
	if loadChapters then
		local chapterDoc = GETDocument(expandAPIURL(novelURL .. "/feed"))
		local chapterJson = json.decode(chapterDoc:text()).chapters
		local chapters = {}
		map(AsList(chapterJson), function (chraw)
			local chapter = NovelChapter {
				title = makeChapterTitle(chraw),
			}
			chapter:setOrder(chraw.id)
			chapter:setLink("/chapters/" .. chraw.id)
			local tierId = chraw.tierId
			if tierId == nil then
				-- ignore all the locked chapter.
				chapters[#chapters + 1] = chapter
			end
		end)
		novel:setChapters(AsList(chapters))
	end
	return novel
end

local function fetchNovelListing()
	local doc = GETDocument("https://api.inoveltranslation.com/novels")
	local contents = json.decode(doc:text())
	local novels = {}
	map(AsList(contents.novels), function (data)
		local coverMeta = data.cover
		-- if coverMeta is null
		local cover = getCoverOrFallback(coverMeta)
		local novel = Novel {
			title = data.title,
			link = "/novels/" .. data.id,
			imageURL = cover,
		}
		novels[#novels + 1] = novel
	end)
	return novels
end

return {
	id = 3239,
	name = "iNoveltranslation",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/iNovel.png",
	chapterType = ChapterType.HTML,

	hasCloudFlare = false,
	hasSearch = false,

	-- Must have at least one value
	listings = {
		-- for now, no incrementals
		Listing("Latest", false, function()
			return fetchNovelListing()
		end),
	},

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
