-- {"id":1331219,"ver":"1.0.2","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://bakapervert.wordpress.com"

local function shrinkURL(url)
	return url:gsub("^.-bakapervert%.wordpress%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(url)
    local content = doc:selectFirst("#content div")
    local p = content:selectFirst(".entry-content")

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    -- get last "p" to remove prev/next links
    local allElements = p:select("p")
    local lastElement = allElements:get(allElements:size()-1)
    if lastElement:children():size() == 3 then
        lastElement:remove()
    end

    return p
end

return {
	id = 1331219,
	name = "bakapervert",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Bakapervert.jpg",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("div#access ul"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Projects", 0, true)) and
						map(v:selectFirst("ul.menu"):select("> li > a"), function(v) return v end)
			end)), function(v)
				return Novel {
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local content = doc:selectFirst("#content div")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title"):text(),
			imageURL = content:selectFirst("img"):attr("src")
		}

		if loadChapters then
			info:setChapters(AsList(map(content:selectFirst(".entry-content"):select("p a"), function(v, i)
				return NovelChapter {
					order = i,
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
