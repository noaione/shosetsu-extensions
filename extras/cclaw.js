// Only for dropped/axed LN
const axios = require('axios').default;
const express = require('express');
const jsdom = require("jsdom");

const { JSDOM } = jsdom;

const router = express.Router();

function Chapter(id, title, order) {
    return {
        id: id,
        title: title,
        order: order || 0,
    }
}

/**
 * 
 * @param {string} id The path ID of the novel
 * @param {string} title The title of the novel
 * @param {string[] | null| undefined} authors The authors of the novel
 * @param {string | null | undefined} cover The cover image of the novel
 * @param {string | null | undefined} description The description of the novel
 * @param {number | null | undefined} status The status of the novel
 * @returns A novel object
 */
function Novel(id, title, authors, cover, description, status) {
    return {
        id: id,
        title: title,
        authors: authors || [],
        cover: cover || null,
        description: description || null,
        // 0: Publishing
        // 1: Completed
        // 2: Paused
        // -1: Unknown
        status: isNone(status) ? -1 : status,
    }
}

function isNone(data) {
    return data === null || typeof data === "undefined";
}

function log(...args) {
    console.log("[ShosetsuAPI][CClaw]", ...args);
}

/**
 * Shrink the URL without base URL
 * @param {string} href URL
 * @returns shrinked URL
 */
function shrinkHPUrl(href) {
    // shrink URL to just the path
    const shrinkUrl = /^https?:\/\/cclawtranslations\.home\.blog\/(.*)$/.exec(href);
    if (isNone(shrinkUrl)) {
        return null;
    }
    return shrinkUrl[1];
}

const CClawDroppedNovels = [
    Novel(
        "demon-lord-guild-master",
        "He Didn’t Want to Be the Center of Attention, Hence, after Defeating the Demon Lord, He Became Guild Master (LN)",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/11/cover-1.png?w=728",
        null,
        -1
    ),
    Novel(
        "isekai-tanjou-2006",
        "Isekai Tanjou 2006",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/10/101-4.png?w=727",
        null,
        -1
    ),
    Novel(
        "f-rank-oniisama",
        "Jishou F-Rank no Oniisama",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/07/101-3.jpg",
        null,
        -1
    ),
    Novel(
        "kou-2-time-leaped",
        "Kou 2 Time Leaped (LN)",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/04/101.png",
        null,
        -1
    ),
    Novel(
        "kujibiki-tokushou-ln",
        "Kujibiki Tokushou: Musou Harem-ken (LN)",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/11/00001cover.png?w=717",
        null,
        -1
    ),
    Novel(
        "naze-boku-no-sekai",
        "Naze Boku no Sekai wo Daremo Oboeteinai no ka?",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/07/101-1-1.jpg",
        null,
        -1
    ),
    Novel(
        "nine-contract-no-91",
        "Nine's Contract Public Enemy Number91",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2020/09/cover.png",
        null,
        -1
    ),
    Novel(
        "osananajimi-love-comedy",
        "Osananajimi ga Zettai ni Makenai Love Comedy",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/10/101-1.jpg?w=722",
        null,
        -1
    ),
]

const CClawAxedNovels = [
    Novel(
        "agi-virtual-girl",
        "AGI -アギ- Virtual Girl Wants to Fall in Love",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/11/cover-1-2.png?w=723",
        null,
        -1,
    ),
    Novel(
        "ie-ni-kaeru-kanojo",
        "Ie ni Kaeru to Kanojo ga Kanarazu Nanika Shiteimasu",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/05/101-7.jpg",
        null,
        -1,
    ),
    Novel(
        "lonely-loser",
        "Lonely Loser (LN)",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2019/05/101.jpg",
        null,
        -1,
    ),
    Novel(
        "motokano-kekkon",
        "Motokano to no Jirettai Gisou Kekkon",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2021/03/101-4.jpg?w=722",
        null,
        -1,
    ),
    Novel(
        "soudana-tashika-kawaii",
        "Soudana, Tashika ni Kawaii Na",
        [],
        "https://cclawtranslationshome.files.wordpress.com/2020/02/101.jpg",
        null,
        -1,
    )
]

const CClawNovelsMapping = [...CClawDroppedNovels, ...CClawAxedNovels];

/// XXX: Demon Lord, Guild Master

const DemonLordGMV1 = [
    Chapter(
        "2019/09/04/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/09/04/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/09/15/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2019/09/30/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2019/10/19/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "2019/11/13/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "2019/11/24/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-chapter-5/",
        "Volume 1 Chapter 5",
        5,
    ),
    Chapter(
        "2019/11/24/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-epilogue/",
        "Volume 1 Epilogue",
        5.5,
    ),
    Chapter(
        "2019/11/24/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-1-afterword/",
        "Volume 1 Afterword",
        5.6,
    )
]

const DemonLordGMV2 = [
    Chapter(
        "2019/12/14/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-2-illustrations/",
        "Volume 2 Illustrations",
        5.8,
    ),
    Chapter(
        "2019/12/14/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-2-prologue/",
        "Volume 2 Prologue",
        5.9,
    ),
    Chapter(
        "2019/12/14/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-2-chapter-1/",
        "Volume 2 Chapter 1",
        6,
    ),
    Chapter(
        "2020/01/14/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-2-chapter-2/",
        "Volume 2 Chapter 2",
        7,
    ),
    Chapter(
        "2020/02/23/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-2-chapter-3/",
        "Volume 2 Chapter 3",
        8,
    ),
    Chapter(
        "2020/05/03/he-didnt-want-to-be-the-center-of-attention-hence-after-defeating-the-demon-lord-he-became-guild-master-ln-volume-2-chapter-4/",
        "Volume 2 Chapter 4",
        9,
    ),
]

/// XXX: Demon Lord, Guild Master (END)

/// XXX: Isekai Tanjou

const IsekaiTanjouV1 = [
    Chapter(
        "2019/10/13/isekai-tanjou-2006-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/10/13/isekai-tanjou-2006-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/10/18/isekai-tanjou-2006-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2019/10/27/isekai-tanjou-2006-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2019/11/16/isekai-tanjou-2006-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "2020/01/10/isekai-tanjou-2006-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "2020/03/20/isekai-tanjou-2006-chapter-5/",
        "Volume 1 Chapter 5",
        5,
    ),
    Chapter(
        "2020/03/20/isekai-tanjou-2006-chapter-6/",
        "Volume 1 Chapter 6",
        6,
    )
]

/// XXX: Isekai Tanjou (END)

/// XXX: Jishou F-Rank Oniisama

const JishouFRankV1 = [
    Chapter(
        "2019/07/27/jishou-f-rank-no-oniisama-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/07/27/jishou-f-rank-no-oniisama-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/07/29/jishou-f-rank-no-oniisama-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2019/08/05/jishou-f-rank-no-oniisama-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2019/08/13/jishou-f-rank-no-oniisama-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    )
]

/// XXX: Jishou F-Rank Oniisama (END)

/// XXX: Kujibiki Tokushou

const KujibikiTokushouV1 = [
    Chapter(
        "2019/11/07/kujibiki-tokushou-musou-harem-ken-ln-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/11/07/kujibiki-tokushou-musou-harem-ken-ln-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/11/08/kujibiki-tokushou-musou-harem-ken-ln-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2019/11/09/kujibiki-tokushou-musou-harem-ken-ln-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2019/11/09/kujibiki-tokushou-musou-harem-ken-ln-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "2019/11/10/kujibiki-tokushou-musou-harem-ken-ln-volume-1-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "2019/11/10/kujibiki-tokushou-musou-harem-ken-ln-volume-1-chapter-5/",
        "Volume 1 Chapter 5",
        5,
    ),
    Chapter(
        "2019/11/28/kujibiki-tokushou-musou-harem-ken-ln-volume-1-chapter-6/",
        "Volume 1 Chapter 6",
        6,
    )
]

/// XXX: Kujibiki Tokushou (END)

/// XXX: Naze Boku no Sekai

const NazeBokuNoSekaiV1 = [
    Chapter(
        "2019/07/09/naze-boku-no-sekai-wo-daremo-oboeteinai-no-ka-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/07/09/naze-boku-no-sekai-wo-daremo-oboeteinai-no-ka-volume-1-illustrations/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/07/15/naze-boku-no-sekai-wo-daremo-oboeteinai-no-ka-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    )
]

/// XXX: Naze Boku no Sekai (END)

/// XXX: Nine's Contract

const NineContractV1 = [
    Chapter(
        "2020/09/11/nines-contract-public-enemy-number91-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2020/09/11/nines-contract-public-enemy-number91-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2020/10/05/nines-contract-public-enemy-number91-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2021/01/24/nines-contract-public-enemy-number91-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    )
]

/// XXX: Nine's Contract (END)

/// XXX: AGI -アギ-

const AGIVirtualGirlV1 = [
    Chapter(
        "2019/12/03/agi-%e3%82%a2%e3%82%ae-virtual-girl-wants-to-fall-in-love-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/12/03/agi-%e3%82%a2%e3%82%ae-virtual-girl-wants-to-fall-in-love-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2020/01/05/agi-%e3%82%a2%e3%82%ae-virtual-girl-wants-to-fall-in-love-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2020/01/28/agi-%e3%82%a2%e3%82%ae-virtual-girl-wants-to-fall-in-love-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "2020/03/07/agi-%e3%82%a2%e3%82%ae-virtual-girl-wants-to-fall-in-love-volume-1-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    )
]

/// XXX: AGI -アギ- (END)

/// XXX: Ie ni Kaeru to Kanojo

const IeNiKaeruKanojoV1 = [
    Chapter(
        "2019/05/17/ie-ni-kaeru-to-kanojo-ga-kanarazu-nanika-shiteimasu-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/05/17/ie-ni-kaeru-to-kanojo-ga-kanarazu-nanika-shiteimasu-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/05/21/ie-ni-kaeru-to-kanojo-ga-kanarazu-nanika-shiteimasu-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    )
]

/// XXX: Ie ni Kaeru to Kanojo (END)

/// XXX: Lonely Loser

const LonelyLoserV1 = [
    Chapter(
        "2019/05/02/lonely-loser-ln-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2019/05/02/lonely-loser-ln-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2019/05/12/lonely-loser-ln-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2019/07/21/lonely-loser-ln-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2020/02/24/lonely-loser-ln-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    )
]

/// XXX: Lonely Loser (END)

/// XXX: Motokano Kekkon

const MotokanoKekkonV1 = [
    Chapter(
        "2021/03/24/motokano-to-no-jirettai-gisou-kekkon-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2021/03/24/motokano-to-no-jirettai-gisou-kekkon-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2021/03/30/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2021/03/30/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2021/03/31/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "2021/04/01/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "2021/04/02/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-5/",
        "Volume 1 Chapter 5",
        5,
    ),
    Chapter(
        "2021/04/02/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-6/",
        "Volume 1 Chapter 6",
        6,
    ),
    Chapter(
        "2021/04/04/motokano-to-no-jirettai-gisou-kekkon-volume-1-chapter-7/",
        "Volume 1 Chapter 7",
        7,
    ),
    Chapter(
        "2021/04/04/motokano-to-no-jirettai-gisou-kekkon-volume-1-epilogue/",
        "Volume 1 Epilogue",
        7.1,
    ),
    Chapter(
        "2021/04/04/motokano-to-no-jirettai-gisou-kekkon-volume-1-afterword/",
        "Volume 1 Afterword",
        7.2,
    ),
]
const MotokanoKekkonV2 = [
    Chapter(
        "2021/07/20/motokano-to-no-jirettai-gisou-kekkon-volume-2-illustrations/",
        "Volume 2 Illustrations",
        7.3,
    ),
    Chapter(
        "2021/07/20/motokano-to-no-jirettai-gisou-kekkon-volume-2-prologue/",
        "Volume 2 Prologue",
        7.4,
    ),
    Chapter(
        "2021/07/20/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-1/",
        "Volume 2 Chapter 1",
        8,
    ),
    Chapter(
        "2021/07/25/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-2/",
        "Volume 2 Chapter 2",
        9,
    ),
    Chapter(
        "2021/07/26/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-3/",
        "Volume 2 Chapter 3",
        10,
    ),
    Chapter(
        "2021/07/26/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-4/",
        "Volume 2 Chapter 4",
        11,
    ),
    Chapter(
        "2021/07/27/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-5/",
        "Volume 2 Chapter 5",
        12,
    ),
    Chapter(
        "2021/07/27/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-6/",
        "Volume 2 Chapter 6",
        13,
    ),
    Chapter(
        "2021/07/28/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-7/",
        "Volume 2 Chapter 7",
        14,
    ),
    Chapter(
        "2021/07/28/motokano-to-no-jirettai-gisou-kekkon-volume-2-chapter-8/",
        "Volume 2 Chapter 8",
        15,
    ),
    Chapter(
        "2021/07/28/motokano-to-no-jirettai-gisou-kekkon-volume-2-epilogue/",
        "Volume 2 Epilogue",
        15.1,
    ),
    Chapter(
        "2021/07/28/motokano-to-no-jirettai-gisou-kekkon-volume-2-afterword/",
        "Volume 2 Afterword",
        15.2,
    ),
]

/// XXX: Motokano Kekkon (END)

/// XXX: Soudana, Tashika

const SoudanaTashikaV1 = [
    Chapter(
        "2020/02/24/soudana-tashika-ni-kawaii-na-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0.1,
    ),
    Chapter(
        "2020/02/24/soudana-tashika-ni-kawaii-na-volume-1-prologue/",
        "Volume 1 Prologue",
        0.2,
    ),
    Chapter(
        "2020/02/25/soudana-tashika-ni-kawaii-na-volume-1-chapter-1/",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "2020/02/25/soudana-tashika-ni-kawaii-na-volume-1-chapter-2/",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "2020/02/26/soudana-tashika-ni-kawaii-na-volume-1-chapter-3/",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "2020/02/27/soudana-tashika-ni-kawaii-na-volume-1-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "2020/02/28/soudana-tashika-ni-kawaii-na-volume-1-chapter-5/",
        "Volume 1 Chapter 5",
        5,
    ),
    Chapter(
        "2020/02/29/soudana-tashika-ni-kawaii-na-volume-1-chapter-6/",
        "Volume 1 Chapter 6",
        6,
    ),
    Chapter(
        "2020/03/01/soudana-tashika-ni-kawaii-na-volume-1-chapter-7/",
        "Volume 1 Chapter 7",
        7,
    ),
    Chapter(
        "2020/03/01/soudana-tashika-ni-kawaii-na-volume-1-epilogue/",
        "Volume 1 Epilogue",
        7.5,
    ),
    Chapter(
        "2020/03/01/soudana-tashika-ni-kawaii-na-volume-1-afterword/",
        "Volume 1 Afterword",
        7.6,
    ),
]

const SoudanaTashikaV2 = [
    Chapter(
        "2020/05/24/soudana-tashika-ni-kawaii-na-volume-2-illustrations/",
        "Volume 2 Illustrations",
        7.7,
    ),
    Chapter(
        "2020/05/24/soudana-tashika-ni-kawaii-na-volume-2-prologue/",
        "Volume 2 Prologue",
        7.8,
    ),
    Chapter(
        "2020/05/24/soudana-tashika-ni-kawaii-na-volume-2-chapter-1/",
        "Volume 2 Chapter 1",
        8,
    ),
    Chapter(
        "2020/05/25/soudana-tashika-ni-kawaii-na-volume-2-chapter-2/",
        "Volume 2 Chapter 2",
        9,
    ),
    Chapter(
        "2020/05/26/soudana-tashika-ni-kawaii-na-volume-2-chapter-3/",
        "Volume 2 Chapter 3",
        10,
    ),
    Chapter(
        "2020/05/27/soudana-tashika-ni-kawaii-na-volume-2-chapter-4/",
        "Volume 2 Chapter 4",
        11,
    ),
    Chapter(
        "2020/05/28/soudana-tashika-ni-kawaii-na-volume-2-chapter-5/",
        "Volume 2 Chapter 5",
        12,
    ),
    Chapter(
        "2020/05/29/soudana-tashika-ni-kawaii-na-volume-2-chapter-6/",
        "Volume 2 Chapter 6",
        13,
    ),
    Chapter(
        "2020/05/29/soudana-tashika-ni-kawaii-na-volume-2-chapter-7/",
        "Volume 2 Chapter 7",
        14,
    ),
    Chapter(
        "2020/05/29/soudana-tashika-ni-kawaii-na-volume-2-chapter-8/",
        "Volume 2 Chapter 8",
        15,
    ),
    Chapter(
        "2020/05/29/soudana-tashika-ni-kawaii-na-volume-2-afterword/",
        "Volume 2 Afterword",
        15.5,
    ),
]

/// XXX: Soudana, Tashika (END)

/// XXX: Osananajimi, Love Comedy

const OsananajimiLoveComedyV1 = [
    Chapter(
        "2019/10/10/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-illustrations/",
        "Volume 1 Illustrations",
        0,
    ),
    Chapter(
        "2019/10/10/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-prologue/",
        "Volume 1 Prologue",
        1,
    ),
    Chapter(
        "2019/10/18/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-1-part-1/",
        "Volume 1 Chapter 1 Part 1",
        2,
    ),
    Chapter(
        "2019/10/22/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-1-part-2/",
        "Volume 1 Chapter 1 Part 2",
        3,
    ),
    Chapter(
        "2019/11/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-part-3/",
        "Volume 1 Chapter 1 Part 3",
        4,
    ),
    Chapter(
        "2019/11/08/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-2-1/",
        "Volume 1 Chapter 2 Part 1",
        5,
    ),
    Chapter(
        "2019/11/15/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-2-part-2/",
        "Volume 1 Chapter 2 Part 2",
        6,
    ),
    Chapter(
        "2019/12/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-2-part-3/",
        "Volume 1 Chapter 2 Part 3",
        7,
    ),
    Chapter(
        "2019/12/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-2-part-4/",
        "Volume 1 Chapter 2 Part 4",
        8,
    ),
    Chapter(
        "2019/12/07/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-2-part-5/",
        "Volume 1 Chapter 2 Part 5",
        9,
    ),
    Chapter(
        "2019/12/07/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-2-part-6/",
        "Volume 1 Chapter 2 Part 6",
        10,
    ),
    Chapter(
        "2019/12/11/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-3-part-1/",
        "Volume 1 Chapter 3 Part 1",
        11,
    ),
    Chapter(
        "2019/12/11/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-3-part-2/",
        "Volume 1 Chapter 3 Part 2",
        12,
    ),
    Chapter(
        "2019/12/13/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-3-part-3/",
        "Volume 1 Chapter 3 Part 3",
        13,
    ),
    Chapter(
        "2019/12/15/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-3-part-4/",
        "Volume 1 Chapter 3 Part 4",
        14,
    ),
    Chapter(
        "2019/12/15/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-4-part-1/",
        "Volume 1 Chapter 4 Part 1",
        15,
    ),
    Chapter(
        "2019/12/18/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-4-part-2/",
        "Volume 1 Chapter 4 Part 2",
        16,
    ),
    Chapter(
        "2019/12/18/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-4-part-3/",
        "Volume 1 Chapter 4 Part 3",
        17,
    ),
    Chapter(
        "2019/12/18/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-4-part-4/",
        "Volume 1 Chapter 4 Part 4",
        18,
    ),
    Chapter(
        "2019/12/21/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-chapter-4-part-5/",
        "Volume 1 Chapter 4 Part 5",
        19,
    ),
    Chapter(
        "2019/12/21/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-epilogue/",
        "Volume 1 Epilogue",
        20,
    ),
    Chapter(
        "2019/12/21/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-1-afterword/",
        "Volume 1 Afterword",
        21,
    ),
]

const OsananajimiLoveComedyV2 = [
    Chapter(
        "2020/01/11/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-illustrations/",
        "Volume 2 Illustrations",
        22,
    ),
    Chapter(
        "2020/01/11/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-prologue/",
        "Volume 2 Prologue",
        23,
    ),
    Chapter(
        "2020/01/26/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-1-part-1/",
        "Volume 2 Chapter 1 Part 1",
        24,
    ),
    Chapter(
        "2020/01/26/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-1-part-2/",
        "Volume 2 Chapter 1 Part 2",
        25,
    ),
    Chapter(
        "2020/02/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-1-part-3/",
        "Volume 2 Chapter 1 Part 3",
        26,
    ),
    Chapter(
        "2020/02/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-1-part-4/",
        "Volume 2 Chapter 1 Part 4",
        27,
    ),
    Chapter(
        "2020/02/08/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-1-part-5/",
        "Volume 2 Chapter 1 Part 5",
        28,
    ),
    Chapter(
        "2020/02/15/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-2-part-1/",
        "Volume 2 Chapter 2 Part 1",
        29,
    ),
    Chapter(
        "2020/02/22/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-2-part-2/",
        "Volume 2 Chapter 2 Part 2",
        30,
    ),
    Chapter(
        "2020/02/29/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-2-part-3/",
        "Volume 2 Chapter 2 Part 3",
        31,
    ),
    Chapter(
        "2020/04/21/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-2-part-4/",
        "Volume 2 Chapter 2 Part 4",
        32,
    ),
    Chapter(
        "2020/05/03/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-3-part-1/",
        "Volume 2 Chapter 3 Part 1",
        33,
    ),
    Chapter(
        "2020/05/30/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-3-part-2/",
        "Volume 2 Chapter 3 Part 2",
        34,
    ),
    Chapter(
        "2020/06/09/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-3-part-3/",
        "Volume 2 Chapter 3 Part 3",
        35,
    ),
    Chapter(
        "2020/06/25/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-4-part-1/",
        "Volume 2 Chapter 4 Part 1",
        36,
    ),
    Chapter(
        "2020/06/27/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-4-part-2/",
        "Volume 2 Chapter 4 Part 2",
        37,
    ),
    Chapter(
        "2020/07/11/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-4-part-3/",
        "Volume 2 Chapter 4 Part 3",
        38,
    ),
    Chapter(
        "2020/07/24/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-4-part-4/",
        "Volume 2 Chapter 4 Part 4",
        39,
    ),
    Chapter(
        "2020/07/24/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-chapter-4-part-5/",
        "Volume 2 Chapter 4 Part 5",
        40,
    ),
    Chapter(
        "2020/07/24/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-afterword/",
        "Volume 2 Afterword",
        41,
    ),
    Chapter(
        "2020/08/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-2-omake/",
        "Volume 2 Omake",
        42,
    ),
]

const OsananajimiLoveComedyV3 = [
    Chapter(
        "2020/08/01/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-3-illustrations/",
        "Volume 3 Illustrations",
        43,
    ),
    Chapter(
        "2020/08/16/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-3-prologue/",
        "Volume 3 Prologue",
        44,
    ),
    Chapter(
        "2020/10/11/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-3-chapter-1-part-1/",
        "Volume 3 Chapter 1 Part 1",
        45,
    ),
    Chapter(
        "2020/10/18/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-3-chapter-1-part-2/",
        "Volume 3 Chapter 1 Part 2",
        46,
    ),
    Chapter(
        "2020/10/25/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-3-chapter-1-part-3/",
        "Volume 3 Chapter 1 Part 3",
        47,
    ),
    Chapter(
        "2020/11/22/osananajimi-ga-zettai-ni-makenai-love-comedy-volume-3-chapter-2-part-1/",
        "Volume 3 Chapter 2 Part 1",
        48,
    ),
]

/// XXX: Osananajimi, Love Comedy (END)

const CClawChaptersMapping = {
    "demon-lord-guild-master": [
        ...DemonLordGMV1,
        ...DemonLordGMV2,
    ],
    "isekai-tanjou-2006": IsekaiTanjouV1,
    "f-rank-oniisama": JishouFRankV1,
    "kujibiki-tokushou-ln": KujibikiTokushouV1,
    "naze-boku-no-sekai": NazeBokuNoSekaiV1,
    "nine-contract-no-91": NineContractV1,
    // TODO:
    "osananajimi-love-comedy": [],
    "agi-virtual-girl": AGIVirtualGirlV1,
    "ie-ni-kaeru-kanojo": IeNiKaeruKanojoV1,
    "lonely-loser": LonelyLoserV1,
    "motokano-kekkon": [
        ...MotokanoKekkonV1,
        ...MotokanoKekkonV2,
    ],
    "soudana-tashika-kawaii": [
        ...SoudanaTashikaV1,
        ...SoudanaTashikaV2,
    ]
}

router.get("/", async (req, res) => {
    res.json({contents: CClawNovelsMapping});
});

router.get("/:id", async (req, res) => {
    const { id } = req.params;
    if (Object.keys(CClawChaptersMapping).includes(id)) {
        // if callable assume async.
        const findNovel = CClawNovelsMapping.findIndex(novel => novel.id === id);
        if (findNovel !== -1) {
            const novel = CClawNovelsMapping[findNovel];
            const HPResult = CClawChaptersMapping[id];
            if (Array.isArray(HPResult)) {
                res.json({contents: {chapters: HPResult, novel}});
            } else if (typeof HPResult === "function") {
                res.json({contents: {chapters: await HPResult(), novel}});
            } else {
                res.status(500).json({contents: {chapters: [], novel}});
            }
        } else {
            res.status(404).json({contents: {chapters: [], novel: null}});
        }
    } else {
        res.status(404).json({contents: {chapters: [], novel: null}});
    }
});

module.exports = router;
