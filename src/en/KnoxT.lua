-- {"id":954053,"ver":"0.2.0","libVer":"1.0.0","author":"N4O","dep":["Bixbox>=1.0.0","WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon")

return Require("Bixbox")("https://knoxt.space", {
    id = 954053,
    name = "KnoxT",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/KnoxT.png",

    --- @param content Element
    stripMechanics = function (content)
        map(content:select("> .code-block"), function (v)
            local text = v:text()
            if WPCommon.contains(text, "Advert") then
                v:remove()
            end
        end)
        map(content:select("a"), function (v)
            local href = v:attr("href")
            if WPCommon.contains(href, "ko-fi") then
                v:remove()
            end
        end)
    end
})