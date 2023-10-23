-- {"id":954054,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["Bixbox>=1.0.0","WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon")

return Require("Bixbox")("https://awebstories.com", {
    id = 954054,
    name = "Awebstories",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Awebstories.png",

    --- @param content Element
    stripMechanics = function (content)
        map(content:children(), function (child)
            local id = child:attr("id")
            if WPCommon.contains(id, "ezoic") then
                child:remove()
            end
        end)
    end
})