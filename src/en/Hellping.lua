-- {"id":221740,"ver":"0.2.0","libVer":"1.0.0","author":"N4O","dep":["NaoAPI>=1.0.0", "WPCommon>=1.0.0"]}

local baseURL = "https://hellping.org"
local apiUrl = "https://naotimes-og.glitch.me/shosetsu-api/hellping/"

local NaoAPI = Require("NaoAPI")
local WPCommon = Require("WPCommon")
NaoAPI.setURL(apiUrl)

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-hellping%.org", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("article")
    local p = content:selectFirst(".entry-content")

	WPCommon.cleanupElement(p)

	map(p:children(), function (v)
		WPCommon.cleanupElement(v)
		local aSelect = v:selectFirst("a")
		local hasA = aSelect and true or false
		local isLinkToToc = hasA and WPCommon.isTocRelated(aSelect:text()) and true or false
		-- local isValidTocData = isTocRelated(v:text()) and isAlignCenter and true or false
		if isLinkToToc then
			v:remove()
		end
	end)

	local postThumb = content:selectFirst(".post-thumbnail")
	if postThumb then
		p:child(0):before(postThumb .. "<hr/>")
	end

	local titleHead = doc:selectFirst("head title")
	if titleHead then
		local title = titleHead:text()
		-- strip " - Hellping text"
		title = title:gsub(" – Hellping", "")
		p:child(0):before("<h2>" .. title .. "</h2><hr/>")
	end

    return p
end

return {
	id = 221740,
	name = "Hellping",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Hellping.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, NaoAPI.getListings)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = NaoAPI.parseNovel,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
