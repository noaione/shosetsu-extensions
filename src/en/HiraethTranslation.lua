-- {"id":43148,"ver":"0.1.4","libVer":"1.0.0","author":"N4O","dep":["Madara>=2.9.2"]}

local function extractSrcSet(srcset)
    -- Get the largest image.
    local max_size, max_url = 0, ""
    for url, size in srcset:gmatch("(http.-) (%d+)w") do
        if tonumber(size) > max_size then
            max_size = tonumber(size)
            max_url = url
        end
    end
    if max_url == "" then
        return nil
    end
    return max_url
end

---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
local function extractLazyLoadedImage(image_element)
	-- Different extensions have the image(s) saved in different attributes. Not even uniformly for one extension.
	-- Partially this comes down to script loading the pictures. Therefore, scour for a picture in the default HTML page.

    -- check data-lazy-srcset
    local srcset = image_element:attr("data-lazy-srcset")
    if srcset ~= "" then
        local dssSrc = extractSrcSet(srcset)
        if dssSrc ~= nil then
            return dssSrc
        end
    end

	-- Check data-srcset:
	srcset = image_element:attr("data-srcset")
	if srcset ~= "" then
		local dssSrc = extractSrcSet(srcset)
        if dssSrc ~= nil then
            return dssSrc
        end
	end

	-- Check data-lazy-src:
	srcset = image_element:attr("data-lazy-src")
	if srcset ~= "" then
		return srcset
	end

    -- Check data-src:
    srcset = image_element:attr("data-src")
    if srcset ~= "" then
        return srcset
    end

	-- Do not use src, as it's a blank svg
	return nil
end

return Require("Madara")("https://hiraethtranslation.com", {
    id = 43148,
    name = "Hiraeth Translations",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Hiraeth.png",

    -- defaults values
    latestNovelSel = "div.page-listing-item",
    ajaxUsesFormData = false,
    hasCloudFlare = true,

    -- There are paid chapters, we can ignore it
    chaptersListSelector = "li.wp-manga-chapter.free-chap",

    genres = {
        "Action",
        -- "Adventure",
        "Comedy",
        -- "Dark Elf",
        -- "Drama",
        "Fantasy",
        "Harem",
        -- "Isekai",
        -- "Mecha",
        -- "Mystery",
        -- "Original Works",
        "Psychological",
        -- "Rom-Com",
        "Romance",
        "Schoo Lifel",
        -- "Shoujo",
        -- "Slice of Life",
        "Seinen",
    },

    --- @param htmlContent Element
    postProcessPassage = function (htmlContent)
        --- check all image element, rewrite it to remove lazyload
        map(htmlContent:select("img"), function (imgEl)
            -- check first, if :src is data:image/svg+xml
            print("Hiraeth Test", imgEl)
            if imgEl:attr("src"):find("data:image/svg+xml") then
                print("Replacing image", imgEl)
                local imgSrc = extractLazyLoadedImage(imgEl)
                if imgSrc then
                    imgEl:attr("src", imgSrc)
                    print("Replaced image", imgEl)
                end
            end
        end)
    end
})
