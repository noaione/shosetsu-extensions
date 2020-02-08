-- rename this if you ever figure out its real name
---@author TechnoJo4
---@version 1.0.0


---@type fun(tbl: table , url: string): string
local qs = Require("url").querystring
local text = function(v) return v:text() end


local defaults = {
    meta_offset = 1,
    ajax_hot = "/ajax/hot-novels",
    ajax_latest = "/ajax/latest-novels",
    ajax_chapters = "/ajax/chapter-option",

    searchTitleSel = ".novel-title",

    hasCloudFlare = false,
    hasSearch = true
}

function defaults:search(data)
    -- search gives covers but they're in some weird aspect ratio
    local doc = GETDocument(qs({ keyword = data.query }, self.baseURL.."/search"))
    local pager = doc:selectFirst(".pagination.pagination-sm")
    local pages = {
        map(doc:select(self.searchTitleSel.." a"), function(v)
            local novel = Novel()
            novel:setLink(self.baseURL..v:attr("href"))
            novel:setTitle(v:attr("title"))
            return novel
        end)
    }

    if pager then
        local last = pager:selectFirst("li.last:not(.disabled) a")
        if not last then
            last = pager:select("li a[data-page]")
            last = last:get(last:size())
        end
        last = tonumber(last:attr("data-page")) + 1

        for i=2, last do
            pages[i] = map(GETDocument(qs({ s = data.query, page = i }, self.baseURL.."/search")):select(".novel-title a"),
                    function(v)
                        local novel = Novel()
                        novel:setLink(v:attr("href"))
                        novel:setTitle(v:attr("title"))
                        return novel
                    end)
        end
    end

    local v = flatten(pages)
    return v
end

function defaults:getPassage(url)
    return table.concat(mapNotNil(GETDocument(url):selectFirst("#chr-content, #chapter-content"):select("p"), text), "\n")
end

function defaults:parseNovel(url, loadChapters)
    local doc = GETDocument(url)
    local info = NovelInfo()

    local elem = doc:selectFirst(".info"):children()
    info:setTitle(doc:selectFirst("h3.title"):text())
    info:setArtists(map(elem:get(self.meta_offset):select("a"), text))
    info:setGenres(map(elem:get(self.meta_offset + 1):select("a"), text))
    info:setStatus(NovelStatus(elem:get(self.meta_offset + 3):select("a"):text() == "Completed" and 1 or 0))

    info:setImageURL(doc:selectFirst("div.book img"):attr("src"))
    info:setDescription(table.concat(map(doc:select("div.desc-text p"), text), "\n"))

    if loadChapters then
        local id = doc:selectFirst("div[data-novel-id]"):attr("data-novel-id")
        local i = 0
        info:setChapters(AsList(map(
                GETDocument(qs({ novelId = id, currentChapterId = "" }, self.ajax_base..self.ajax_chapters)):selectFirst("select"):children(),
                function(v)
                    local chap = NovelChapter()
                    chap:setLink(self.baseURL..v:attr("value"))
                    chap:setTitle(v:text())
                    chap:setOrder(i)
                    i = i + 1
                    return chap
                end)))
    end

    return info
end

return function(baseURL, _self)
    _self = setmetatable(_self or {}, { __index = function(_, k)
        local d = defaults[k]
        return (type(d) == "function" and wrap(_self, d) or d)
    end })

    _self["baseURL"] = baseURL
    if not _self["ajax_base"] then
        _self["ajax_base"] = baseURL
    end

    _self["listings"] = {
        Listing("Hot", false, function()
            return map(GETDocument(_self.ajax_base .. _self.ajax_hot):select("div.item a"), function(v)
                local novel = Novel()
                novel:setImageURL(v:selectFirst("img"):attr("src"))
                novel:setTitle(v:attr("title"))
                novel:setLink(baseURL..v:attr("href"))
                return novel
            end)
        end),
        Listing("Latest", false, function()
            return map(GETDocument(_self.ajax_base .. _self.ajax_latest):select("div.row .col-title a"), function(v)
                local novel = Novel()
                novel:setTitle(v:text())
                novel:setLink(baseURL..v:attr("href"))
                return novel
            end)
        end)
    }
    return _self
end