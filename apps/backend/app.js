const axios = require("axios").default;
const express = require("express");
const app = express();
const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const daprBaseUrl = `http://localhost:${daprPort}/v1.0`

app.listen(3000, () => {
    console.log("Server running on port 3000");
});

app.get("/:id", (req, res) => {
    const response = await axios.get(`${daprBaseUrl}/state/statestore/${req.params.id}`);
    res.json(response.data);
});

app.post("/:id", (req, res) => {
    const response = await axios.post(`${daprBaseUrl}/state/statestore`, [
        {
            key: req.params.id,
            value: req.body
        }
    ]);

    console.log(response.data);
})

