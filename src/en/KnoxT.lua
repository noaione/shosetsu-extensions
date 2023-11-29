-- {"id":954053,"ver":"0.3.0","libVer":"1.0.0","author":"N4O","dep":["Bixbox>=1.1.0","WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon")

return Require("Bixbox")("https://knoxt.space", {
    id = 954053,
    name = "KnoxT",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/KnoxT.png",

    availableGenres = {
        "Action",
        "Adult",
        "Adventure",
        "Ancient times",
        "BL",
        "carefree protagonist",
        "celebrity",
        "Chinese novel",
        "Comedy",
        "Cooking",
        "Drama",
        "Entertaiment circle",
        "Entertainment circle",
        "Fantasy",
        "Fiction",
        "futuristic setting",
        "Gaming",
        "Gender Bender",
        "General",
        "GL",
        "Harem",
        "Historical",
        "Horror",
        "humor",
        "Idol",
        "infrastructure",
        "interstellar",
        "Josei",
        "love at first sight",
        "Male protagonist",
        "Martial Arts",
        "Mature",
        "Mecha",
        "Modern",
        "Mystery",
        "Omegaverse",
        "Otherworld fantasy",
        "Psychological",
        "Quick transmigration",
        "REBIRTH",
        "Regression",
        "Reverse Harem",
        "Romance",
        "School Life",
        "Sci-fi",
        "Seinen",
        "shonen ai",
        "Shoujo",
        "Shoujo ai",
        "Shounen",
        "Shounen ai",
        "Showbi",
        "showbiz",
        "Slice of Life",
        "Smut",
        "Sports",
        "Supernatural",
        "Tragedy",
        "Transmigration",
        "Unlimited flow",
        "Urban Life",
        "Western",
        "Wu xia",
        "Xianxia",
        "Xuanhuan",
        "Yaoi",
        "Yuri"
    },

    availableTypes = {
        "Chinese Novel",
        "Japanese Novel",
        -- "Kō Randō (藍銅 紅)", -- might broke something
        "Korean Novel",
        "Light Novel (CN)",
        "Original Novel",
        "Published Novel",
        "Published Novel (KR)",
        "Short Story",
        "Web Novel"
    },

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