-- {"id":4212306,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["Madara>=2.9.0"]}

return Require("Madara")("https://galaxytranslations97.com", {
    id = 4212306,
    name = "Galaxy Translations",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/GalaxyTL.png",

    -- defaults values
    latestNovelSel = "div.page-listing-item",
    ajaxUsesFormData = false,

    -- There are paid chapters, we can ignore it
    chaptersListSelector= "li.wp-manga-chapter.free-chap",

    -- genres = {
    --     "Chinese Novel",
    --     "Japanese Novel",
    --     "Korean Novel",
    -- },

    genres = {
        "Action",
        "Adventure",
        "Comedy",
        "Drama",
        "Ecchi",
        "Fantasy",
        "Harem",
        "Mecha",
        "Romance",
        "School Life",
        "Sci-fi",
        "Shoujo",
        "Shounen",
        "Shounen Ai",
        "Slice of Life",
        "Supernatural",
        "Yaoi"
    },

    shrinkURLNovel = "manga",
    novelListingURLPath = "manga",
})
