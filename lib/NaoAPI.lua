-- {"ver":"1.0.0","author":"N4O","dep":["dkjson"]}

-- A common function to handle the custom mirror API that I made

local json = Require("dkjson")

local NaoAPI = {}
--- @type string|nil
NaoAPI._baseAPIUrl = nil -- change later

--- @param str string
--- @param pattern string
local function contains(str, pattern)
	return str:find(pattern, 0, true) and true or false
end


function NaoAPI._checkAPIUrl()
    if NaoAPI._baseAPIUrl == nil then
        error("NaoAPI._baseAPIUrl is nil. Please set it with NaoAPI.setURL()")
    end
end

--- @param apiUrl string
function NaoAPI.setURL(apiUrl)
    -- append a slash if it doesn't exist
    if apiUrl:sub(-1) ~= "/" then
        apiUrl = apiUrl .. "/"
    end
    NaoAPI._baseAPIUrl = apiUrl
end

--- @return table
function NaoAPI.getListings()
    NaoAPI._checkAPIUrl()
    local doc = GETDocument(NaoAPI._baseAPIUrl)
    local contents = json.decode(doc:text())
    return map(contents.contents, function(v)
        return Novel {
            title = v.title,
			imageURL = v.cover,
            -- for custom handling
			link = "shosetsu-api/" .. v.id .. "/",
			description = v.description,
			authors = v.authors,
        }
    end)
end


--- @param url string
--- @param loadChapters boolean
function NaoAPI.parseNovel(url, loadChapters)
	-- strip the shosetsu-api/ part
    if not contains(url, "shosetsu-api/") then
        return nil
    end
    NaoAPI._checkAPIUrl()
	local id = url:sub(14, -2)
	local doc = GETDocument(NaoAPI._baseAPIUrl .. id)
	local jsonRes = json.decode(doc:text()).contents
	local novel = jsonRes.novel

	local info = NovelInfo {
		title = novel.title,
		imageURL = novel.cover,
		authors = novel.authors,
    }
	if novel.description ~= nil then
		info:setDescription(novel.description)
	end
	if novel.status ~= nil then
		info:setStatus(NovelStatus(novel.status))
	end

	if loadChapters then
		info:setChapters(AsList(map(jsonRes.chapters, function (v)
			return NovelChapter {
				order = v.order,
				title = v.title,
				link = "/" .. v.id,
				-- release = v.release,
			}
		end)))
	end
	return info
end

return NaoAPI
