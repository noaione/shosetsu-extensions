const hellping = require("./hellping");
const cclaw = require("./cclaw");
const express = require("express");

const router = express.Router();

router.get("/", (req, res) => {
    res.json({
        "contents": [
            {
                "id": "hellping",
                "name": "Hellping",
                "host": "https://hellping.org"
            },
            {
                "id": "cclaw",
                "name": "CClaw Translations",
                "host": "https://cclawtranslations.home.blog"
            }
        ]
    })
})
router.use("/hellping", hellping);
router.use("/cclaw", cclaw);

module.exports = router;