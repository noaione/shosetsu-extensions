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

function isNone(data) {
    return data === null || typeof data === "undefined";
}

function log(...args) {
    console.log("[ShosetsuAPI][Hellping]", ...args);
}

/**
 * Shrink the URL without base URL
 * @param {string} href URL
 * @returns shrinked URL
 */
function shrinkHPUrl(href) {
    // shrink URL to just the path
    const shrinkUrl = /^https?:\/\/hellping\.org\/(.*)$/.exec(href);
    if (isNone(shrinkUrl)) {
        return null;
    }
    return shrinkUrl[1];
}


/**
 * Expand short URL to full URL
 * @param {string} url 
 */
async function expandHPShortURL(url) {
    if (url.startsWith("wp-admin")) {
        // regex to get the url
        const match = /wp-admin\/post\.php\?post=(\d+)&action=edit/.exec(url);
        if (match === null) {
            return null;
        }
        const id = match[1];
        url = `https://hellping.org/?p=${id}`;
    } else {
        url = `https://hellping.org/${url}`;
    }
    try {
        const tempDoc = await axios.get(url, {
            responseType: "text",
        });
        const request = tempDoc.request;
        if (isNone(request)) return null;
        const response = request.res || {};
        return response.responseUrl || request.responseUrl
    } catch (err) {
        log(err);
        return null;
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

const HellPingNovelMappings = [
    Novel(
        "motokano",
        "My Stepmom's Daughter Is My Ex",
        ["Kyousuke Kamishiro"],
        "https://hellping.org/wp-content/uploads/2020/05/b.png",
        `In what can only be called a folly of youth, I had a girlfriend towards the end of middle school.
Thank god we broke up! There’s no girl nastier than her.
I never want to see her again! Wait, who’s that with my stepmom?!
Oh god, it’s her!`,
        0
    ),
    Novel(
        "sunday-without-god",
        "Sunday Without God",
        ["Kimihito Irie"],
        "https://hellping.org/wp-content/uploads/2020/03/cover.jpg",
        `God has abandoned the world. As a result, life cannot end nor can new life be born,
and the "dead" walk restlessly among the living. Granting one last miracle before turning away forever,
God created "gravekeepers," mystical beings capable of putting the dead to rest through a proper burial.
Ai, a cheerful but naïve young girl, serves as her village's gravekeeper in place of her late mother.

One day, a man known as Hampnie Hambart, who is supposedly Ai's father, arrives and kills all the people in her village.
Having lost her village and with no plans for the future, Ai decides to accompany the mysterious man on his journey.
As she travels the land, the young gravekeeper strives to fulfill her duties,
granting peace to the dead and assisting the living,
while at the same time learning more about the world that God left in this tragic state.`,
        0,
    ),
    Novel(
        "3-minutes-boy-meets-girl",
        "3 Minutes Boy Meets Girl",
        [
            "Sennedou Taguchi",
            "Akira",
            "Sadanatsu Anda",
            "Akihiko Ureshino",
            "Ichirou Sakaki",
            "Takaaki Kaima",
            "Mizuki Nomura",
            "Keishi Ayasato",
            "Miyabi Hasegawa",
            "Shin Araki",
            "Shio Sasahara",
            "Noritake Tao",
            "Kenji Inoue"
        ],
        "https://2.bp.blogspot.com/-FnGznaxT03Q/UkxAF8nrLWI/AAAAAAAAAGI/zl8fNsmMCfE/s1600/3minutes000d.jpg",
        `"3 Minutes Boy Meets Girl" is an anthology of short stories produced by the authors working at Famitsu Bunko. There are 19 chapters from 19 different authors.`,
        0,
    ),
    Novel(
        "amaryllis-in-the-ice-country",
        "Amaryllis in the Ice Country",
        ["Takeshi Matsuyama"],
        "https://hellping.org/wp-content/uploads/2015/12/000B.jpg",
        `In the distant future, the world was in ice
Humans live in cryo facilities underground, awaiting for the distant Spring,
Robots manage the facilities, they built a ‘village’ there and lived there.
They dreamed that, one day, they would live together with the "Humans" (Master).
This, is the story of the Ice Country.`,
        1,
    ),
    Novel(
        "angel",
        "The Angel Next Door Spoils Me Rotten",
        ["Saekisan"],
        "https://hellping.org/wp-content/uploads/2020/04/Angelv1-Cover-1.jpeg",
        `Mahiru is a beautiful girl whose classmates all call her an “angel.”
Not only is she a star athlete with perfect grades—she’s also drop-dead gorgeous.
Amane‚ an average guy and self-admitted slob‚ has never thought much of the divine beauty‚
despite attending the same school. Everything changes‚ however‚ when he happens to see
Mahiru sitting alone in a park during a rainstorm. Thus begins the strange relationship
between this incredibly unlikely pair!`,
        0,
    ),
    Novel(
        "biblia",
        "Biblia Koshodou no Jiken Techou",
        ["Mikami En"],
        "https://hellping.org/wp-content/uploads/2013/09/Biblia1_000b.jpg",
        `Biblia Koshodou no Jiken Techou is a mystery series in which Shinokawa Shioriko,
a young owner of a bookstore in Kamakura, unravels the mysteries of ancient books stolen from the shop.`,
3,
    ),
    Novel(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai",
        "Failure is Forbidden! Her secret shall never be revealed!",
        ["Masaki Masamune"],
        "https://www.baka-tsuki.org/project/images/b/ba/ShippaiKinshi_V1_Cover.jpg",
        `Seiryuu Academy, the Second Flower Decoration Club—This club that gathers the top beauties in
the school is a mysterious organization of unknown activities and admission conditions.
The protagonist, Shimizu Shou, due to some strange opportunity, was recommended to enter the
Second Flower Decoration Club by his sister Hijiri, a member of the club. “Bro-Brother, that stain... perhaps...?”
"That’s not it, Hijiri! It’s just spilled orange juice!" ...the conditions needed to join the club that are shrouded in mystery are...?`,
        0
    ),
    Novel(
        "86-2",
        "86: Side Stories",
        ["Asato Asato"],
        "https://hellping.org/wp-content/uploads/2017/09/cover.jpg",
        `The Republic of San Magnolia has been attacked by its neighbor, the Empire.
Outside the 85 districts of the Republic there is the 'non-existent 86th district,' where
young men and women continue to fight. Sheen directs the actions of young suicide bombers,
while Lena is a “curator” who commands a detachment from a remote rear.`,
0,
    )
]

/// XXX: Motokano

const MotoKanoV1 = [
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-1/",
        "Volume 1 Chapter 1 – The ex-couple refuses to address each other (This is what I hate about you)",
        1,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-2/",
        "Volume 1 Chapter 2 – The ex-couple watch the house (It’s my house. That’s normal, right?)",
        2,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-3/",
        "Volume 1 Chapter 3 – The ex-couple’s going to school (You feeling lonely?)",
        3,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-4/",
        "Volume 1 Chapter 4 – The ex-couple goes for a test (...it smells of sweat)",
        4,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-5/",
        "Volume 1 Chapter 5 – The ex-boyfriend’s caring for the sick (Easy peasy)",
        5,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-6",
        "Volume 1 Chapter 6 – In the house, the ex-girlfriend waits dreaming",
        6,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-7-first-half/",
        "Volume 1 Chapter 7.1 – The ex-couple XXXX, First Half (Please go out with me, and that we’ll get married in the future)",
        7.1,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-7-second-half/",
        "Volume 1 Chapter 7.2 – The ex-couple goes on a date, Second Half (Shitty Maniac) (Shitty otaku)",
        7.2,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-chapter-8/",
        "Volume 1 Chapter 8 – The couple exchange gifts. (I wanna die)",
        8,
    ),
    Chapter(
        "motokano/motokano-v1/motokano-v1-afterword/",
        "Volume 1 Afterword - Instead of an afterword: A comment on every chapter",
        8.5,
    ),
]

const MotoKanoV2 = [
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-1/",
        "Volume 2 Chapter 1 – A snapshot of the ex-couple’s daily life (How to live through Golden Week)",
        9,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-2/",
        "Volume 2 Chapter 2 – The ex-couple change seats (...0.325%...)",
        10,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-3/",
        "Volume 2 Chapter 3 – The ex-couple lean on each other (I’m the older sister after all)",
        11,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-4/",
        "Volume 2 Chapter 4 – The ex-couple stays over (Help yourselves)",
        12,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-5/",
        "Volume 2 Chapter 5 – The ex-couple Contest each other (Don’t take me as an idiot!!)",
        13,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-6",
        "Volume 2 Chapter 6 – The ex isn’t jealous (Thank you for being friends with Mizuto)",
        14,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-chapter-7/",
        "Volume 2 Chapter 7 – Isana Higashira doesn’t know love",
        15,
    ),
    Chapter(
        "motokano/motokano-v2/motokano-v2-afterword/",
        "Volume 2 Afterword – New Age of happiness",
        15.5,
    ),
]

/// XXX: Motokano (END)

/// XXX: 3 Minutes Boy Meets Girl

const ThreeMinutesBoyMeetsGirlV1 = [
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
        "Chapter 1: 3 min.30cm (Sennedou Taguchi)",
        1,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-2/",
        "Chapter 2: The ills of the filling-in education and the girl at a corner of the classroom (Akira)",
        2,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-319-decisively-attending-a-life-changing-interview/",
        "Chapter 3: Decisively Attending a Life-Changing Interview (Sadanatsu Anda)",
        3,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-419-cat-teasing/",
        "Chapter 4: Cat Teasing (Akihiko Ureshino)",
        4,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
        "Chapter 5: 3 min God (Ichirou Sasaki)",
        5,
    ),
    // Chapter(
    //     "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
    //     "Chapter 6: ",
    // ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-719-pour-some-water/",
        "Chapter 7: Pour some water (Takaaki Kaima)",
        7,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/chapter-8-come-here-kitty/",
        "Chapter 8: Come here, Kitty (Mizuki Nomura)",
        8,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-9-19-the-neon-tetra-dilemma/",
        "Chapter 9: The Neon Tetra Dilemma (Keishi Ayasato)",
        9,
    ),
    // Chapter(
    //     "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
    //     "Chapter 10: ",
    // ),
    // Chapter(
    //     "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
    //     "Chapter 11: ",
    // ),
    // Chapter(
    //     "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
    //     "Chapter 12: ",
    // ),
    // Chapter(
    //     "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
    //     "Chapter 13: ",
    // ),
    // Chapter(
    //     "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-119-3-min-30cm/",
    //     "Chapter 14: ",
    // ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-1519-3-minutes-of-abcd/",
        "Chapter 15: 3 Minutes of ABCD... (Miyabi Hasegawa)",
        15,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-1619-haruka-sugimiya-is-a-real-man/",
        "Chapter 16: Haruka Sugimiya is a real man! (Shin Araki)",
        16,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-1719-call/",
        "Chapter 17: Call (Shio Sasahara)",
        17,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-1819-her-tendencies-and-how-to-counter-them/",
        "Chapter 18: Her Tendencies, and how to Counter Them (Noritake Tao)",
        18,
    ),
    Chapter(
        "3-minutes-boy-meets-girl/3-minutes-boy-meets-girl-chapter-1919-three-minutes-boy-meets-girl/",
        "Chapter 19: Three Minutes, Boy Meets Girl (Kenji Inoue)",
        19,
    ),
]

/// XXX: 3 Minutes Boy Meets Girl (END)

/// XXX: Amaryllis in the Ice Country

const AmaryllisCountryV1 = [
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-prologue/",
        "Prologue",
        0,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-1/",
        "Chapter 1",
        1,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-2/",
        "Chapter 2",
        2,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-3/",
        "Chapter 3",
        3,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-4/",
        "Chapter 4",
        4,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-5/",
        "Chapter 5",
        5,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-6/",
        "Chapter 6",
        6,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-7/",
        "Chapter 7",
        7,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-8/",
        "Chapter 8",
        8,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-9/",
        "Chapter 9",
        9,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-10/",
        "Chapter 10",
        10,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-chapter-10/",
        "Epilogue",
        11,
    ),
    Chapter(
        "amaryllis-in-the-ice-country/amaryllis-afterword/",
        "Afterword",
        11.5,
    )
]

/// XXX: Amaryllis in the Ice Country (END)

/// XXX: Angel Next Door

/**
 * 
 * @param {HTMLElement} element 
 */
function isAngelWNLinkInWebNovelSection(element) {
    while (element.previousElementSibling !== null) {
        element = element.previousElementSibling;
        if (element.textContent.includes("WEB NOVEL") && element.style.textAlign === "center") {
            return true;
        }
    }
    return false;
}

/**
 * 
 * @param {HTMLElement} element 
 */
function angelWNWalkthroughSiblings(element) {
    while (element.nextElementSibling !== null) {
        if (element.textContent.includes("WEB NOVEL") && element.style.textAlign === "center") {
            return element;
        }
        element = element.nextElementSibling;
    }
    return null;
}

async function AngelNextDoorWN() {
    /** @type {string | null} */
    let documentStr = null;
    log("[Angel WN] Getting pages...")
    try {
        const tempDoc = await axios.get("https://hellping.org/angel/", {
            responseType: "text",
        });
        documentStr = tempDoc.data;
    } catch (err) {
        log(err);
        return [];
    }

    log("[Angel WN] Creating JSDOM document")
    const dom = new JSDOM(documentStr);
    const { document } = dom.window;
    log("[Angel WN] Getting entry content")
    const entryContent = document.querySelector("article > .entry-content");
    if (isNone(entryContent)) {
        return [];
    }
    // get all the links
    const entryChild = entryContent.firstElementChild;
    if (isNone(entryChild)) {
        return [];
    }
    log("[Angel WN] Finding start of WN links")
    let wnStartElement = angelWNWalkthroughSiblings(entryChild);
    if (isNone(wnStartElement)) {
        return [];
    }
    log("[Angel WN] Found start of WN links", wnStartElement.ATTRIBUTE_NODE);
    // const links = entryContent.querySelectorAll("a");
    const chapters = [];
    log("[Angel WN] Finding WN links...")
    while (wnStartElement.nextElementSibling !== null) {
        wnStartElement = wnStartElement.nextElementSibling;
        const i = chapters.length;
        const chapterName = (wnStartElement.textContent || `Chapter ${i + 1}`).trimStart();
        // find "a" links.
        const link = wnStartElement.querySelector("a");
        if (isNone(link)) {
            continue;
        }
        const href = link.getAttribute("href");
        if (isNone(href)) {
            continue;
        }
        if (!href.includes("hellping.org")) {
            continue;
        }
        // mitigate chapters that somehow are stupidly linked
        if (!chapterName.startsWith("Chapter")) {
            log(`[Angel WN] Chapter ${i + 1} (${chapterName}) doesn't start with "Chapter"`);
            continue;
        }
        let chapterPath = shrinkHPUrl(href);
        if (isNone(chapterPath)) {
            continue;
        }
        // "Continue" image
        if (chapterPath.startsWith("wp-content")) {
            continue;
        }
        // Expand link that are like this `?p=1234`
        // or `wp-admin/post.php?post=1234&action=edit`
        if (chapterPath.startsWith("?p=") || chapterPath.startsWith("wp-admin")) {
            log("[Angel WN] Expanding link", chapterName)
            chapterPath = shrinkHPUrl(await expandHPShortURL(chapterPath));
            if (isNone(chapterPath)) {
                continue;
            }
        }
        chapters.push(Chapter(chapterPath, chapterName, i + 1));
    }
    log("[Angel WN] Found WN links", chapters.length)
    return chapters;
}

/// XXX: Angel Next Door (END)

/// XXX: Biblia

const BibliaV1V2 = [
    Chapter(
        "biblia-v1-prologue",
        "Volume 1 Prologue",
        0,
    ),
    Chapter(
        "biblia-v1-chapter-1-natsume-soseki-sosekis-complete-collection-new-edition-iwanami-shote",
        "Volume 1 Chapter 1",
        1,
    ),
    Chapter(
        "biblia-v1-chapter-2-kiyoshi-koyama-monument-gleaning-saint-andersen-shincho-paperback",
        "Volume 1 Chapter 2",
        2,
    ),
    Chapter(
        "biblia-v1-chapter-3-vinogradovkuzmin-introduction-to-logic-aoki-paperback",
        "Volume 1 Chapter 3",
        3,
    ),
    Chapter(
        "biblia-v1-chapter-4-osamu-dazai-the-late-years-sunagoya-bookstore",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "biblia-v1-epilogue",
        "Volume 1 Epilogue",
        5,
    ),
    Chapter(
        "biblia-v1-chapter-2-kiyoshi-koyama-monument-gleaning-saint-andersen-shincho-paperback",
        "Volume 1 Afterword",
        6,
    ),
    Chapter(
        "biblia-v2-prologue",
        "Volume 2 Prologue",
        7,
    ),
]

/// XXX: Biblia (END)

/// XXX: Shippai Kinshi

const ShippaiKinshiV1 = [
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-chapter-1-shocking-fact-the-maidens-yard-is-a-yellow-flowering-garden/",
        "Volume 1 Chapter 1: Shocking Fact! The Maidens' Yard is a Yellow Flowering Garden!",
        1,
    ),
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-chapter-2-entrance-test-the-self-proclaimed-archmage-arrives-at-the-second-flower-arrangement-club/",
        "Volume 1 Chapter 2: Entrance Test! The Self-Proclaimed Archmage Arrives at the Second Flower Arrangement Club!",
        2,
    ),
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-chapter-3-recruiting-a-member-a-red-haired-girl-who-absolutely-hates-to-lose/",
        "Volume 1 Chapter 3: Recruiting a Member! A red-haired girl who absolutely hates to lose!",
        3,
    ),
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-chapter-4/",
        "Volume 1 Chapter 4",
        4,
    ),
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-chapter-5/",
        "Volume 1 Chapter 5",
        5,
    ),
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-epilogue/",
        "Volume 1 Epilogue",
        6,
    ),
    Chapter(
        "shippai-kinshi-kanojo-no-himitsu-wa-morasanai/shikkin-v1-afterwords/",
        "Volume 1 Afterword",
        7,
    ),
]

/// XXX: Shippai (END)

/// XXX: 86: Side Stories

async function EightySixSideStories() {
    /** @type {string | null} */
    let documentStr = null;
    log("[86SS] Getting pages...")
    try {
        const tempDoc = await axios.get("https://hellping.org/86-2/86-side-stories/", {
            responseType: "text",
        });
        documentStr = tempDoc.data;
    } catch (err) {
        log(err);
        return [];
    }

    log("[86SS] Creating JSDOM document")
    const dom = new JSDOM(documentStr);
    const { document } = dom.window;
    log("[86SS] Getting entry content")
    const entryContent = document.querySelector("article > .entry-content");
    if (isNone(entryContent)) {
        return [];
    }
    // get all the links
    const allOrderedList = entryContent.querySelectorAll("ol");
    if (isNone(allOrderedList)) {
        return [];
    }
    const chapters = [];
    log("[86SS] Getting chapters...",allOrderedList.length)
    for (let j = 0; j < allOrderedList.length; j++) {
        const orderedList = allOrderedList[j];
        const prevSibling = orderedList.previousElementSibling;
        let prependText = "";
        if (!isNone(prevSibling)) {
            prependText = (prevSibling.textContent + " " || "") + " ";
            prependText = prependText.trimStart();
        }

        const allLinks = orderedList.querySelectorAll("li");
        log(`[86SS] Getting chapters from list ${j}...`)
        for (let k = 0; k < allLinks.length; k++) {
            const linkList = allLinks[k];
            const i = chapters.length;
            const chapterName = prependText + (linkList.textContent || `Chapter ${i + 1}`).trimStart();
            const link = linkList.querySelector("a");
            if (isNone(link)) {
                continue;
            }
            const href = link.getAttribute("href");
            if (isNone(href)) {
                continue;
            }
            if (!href.includes("hellping.org")) {
                continue;
            }
            let chapterPath = shrinkHPUrl(href);
            if (isNone(chapterPath)) {
                continue;
            }
            // "Continue" image
            if (chapterPath.startsWith("wp-content")) {
                continue;
            }
            // Expand link that are like this `?p=1234`
            // or `wp-admin/post.php?post=1234&action=edit`
            if (chapterPath.startsWith("wp-admin")) {
                log("[86SS] Expanding link", chapterName)
                chapterPath = shrinkHPUrl(await expandHPShortURL(chapterPath));
                if (isNone(chapterPath)) {
                    continue;
                }
            }
            chapters.push(Chapter(chapterPath, chapterName, i + 1));
        }
    }
    log("[86SS] Done getting chapters, total:", chapters.length)
    return chapters;
}

/// XXX: 86: Side Stories (END)

const HellPingChaptersMappings = {
    "motokano": [
        ...MotoKanoV1,
        ...MotoKanoV2,
        // TODO: add v03-08 and SS
    ],
    "3-minutes-boy-meets-girl": ThreeMinutesBoyMeetsGirlV1,
    "amaryllis-in-the-ice-country": AmaryllisCountryV1,
    "angel": AngelNextDoorWN,
    "biblia": [...BibliaV1V2],
    "shippai-kinshi-kanojo-no-himitsu-wa-morasanai": [...ShippaiKinshiV1],
    "86-2": EightySixSideStories,
    "sunday-without-god": [],
}

router.get("/", async (req, res) => {
    res.json({contents: HellPingNovelMappings});
});

router.get("/:id", async (req, res) => {
    const { id } = req.params;
    if (Object.keys(HellPingChaptersMappings).includes(id)) {
        // if callable assume async.
        const findNovel = HellPingNovelMappings.findIndex(novel => novel.id === id);
        if (findNovel !== -1) {
            const novel = HellPingNovelMappings[findNovel];
            const HPResult = HellPingChaptersMappings[id];
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
