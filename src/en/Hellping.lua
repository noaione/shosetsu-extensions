-- {"id":221740,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["dkjson>=1.0.1"]}

local baseURL = "https://hellping.org/"
local apiUrl = "https://naotimes-og.glitch.me/shosetsu-api/hellping/"

local json = Require("dkjson")

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

--- @param testString string
--- @return boolean
local function isTocRelated(testString)
	testString = testString:lower()

	-- check "ToC"
	if testString:find("ToC", 0, true) then
		return true
	end
	if testString:find("toc", 0, true) then
		return true
	end
	if testString:find("table of content", 0, true) then
		return true
	end
	if testString:find("table of contents", 0, true) then
		return true
	end
	if testString:find("Table of content", 0, true) then
		return true
	end
	if testString:find("Table of contents", 0, true) then
		return true
	end
	if testString:find("Table of Content", 0, true) then
		return true
	end
	if testString:find("Table of Contents", 0, true) then
		return true
	end

	-- check "Previous"
	if testString:find("Previous", 0, true) then
		return true
	end
	if testString:find("previous", 0, true) then
		return true
	end
	if testString:lower():find("back to", 0, true) then
		return true
	end

	-- check "Next"
	if testString:find("Next", 0, true) then
		return true
	end
	if testString:find("next", 0, true) then
		return true
	end
	if testString:lower():find("forward to", 0, true) then
		return true
	end
	return false
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("article")
    local p = content:selectFirst(".entry-content")

	local dark_switch = p:selectFirst("div.wp-dark-mode-switcher")
	if dark_switch then dark_switch:remove() end

	map(p:children(), function (v)
		local className = v:attr("class")
		if className:find("patreon_button") then
			v:remove()
		end
		if className:find("sharedaddy") then
			v:remove()
		end
		if className:find("wp-post-navigation", 0, true) and true or false then
			v:remove()
		end
		if className:find("wpulike", 0, true) and true or false then
			v:remove()
		end
		local aSelect = v:selectFirst("a")
		local hasA = aSelect and true or false
		local isLinkToToc = hasA and isTocRelated(aSelect:text()) and true or false
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
		Listing("Novels", false, function()
			local doc = GETDocument(apiUrl)
			local json = json.decode(doc:text())
			return map(json.contents, function (v)
				return Novel {
					title = v.title,
					imageURL = v.cover,
					link = v.id .. "/",
					description = v.description,
					authors = v.authors,
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(apiUrl .. novelURL)
		local jsonRes = json.decode(doc:text()).contents
		local novel = jsonRes.novel

		local info = NovelInfo {
			title = novel.title,
			imageURL = novel.cover,
			description = novel.description,
			authors = novel.authors,
			-- genres = jsonRes.genres,
			-- status = NovelStatus(jsonRes.status),
		}
		if novel.status ~= nil then
			info:setStatus(NovelStatus(novel.status))
		end

		if loadChapters then
			info:setChapters(AsList(map(jsonRes.chapters, function (v)
				return NovelChapter {
					order = v.order,
					title = v.title,
					link = shrinkURL(expandURL(v.id)),
					-- release = v.release,
				}
			end)))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
