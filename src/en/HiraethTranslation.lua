-- {"id":43148,"ver":"0.1.1","libVer":"1.0.0","author":"N4O","dep":["Madara>=2.9.0"]}

return Require("Madara")("https://hiraethtranslation.com", {
    id = 43148,
    name = "Hiraeth Translations",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Hiraeth.png",

    -- defaults values
    latestNovelSel = "div.page-listing-item",
    ajaxUsesFormData = false,

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
    }
})
