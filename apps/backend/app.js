
const express = require("express");
const app = express();

app.listen(3000, () => {
    console.log("Server running on port 3000");
});

app.get("/", (req, res, next) => {
    res.json(["abc", "def", 123, "9123"]);
});

