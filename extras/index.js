const hellping = require("./hellping");
const express = require("express");

const router = express.Router();

router.get("/", (req, res) => {
    res.json({
        "contents": [
            {
                "id": "hellping",
                "name": "Hellping",
                "host": "https://hellping.org"
            }
        ]
    })
})
router.use("/hellping", hellping);

module.exports = router;