const axios = require("axios").default;
const express = require("express");
const app = express();
const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const daprBaseUrl = `http://localhost:${daprPort}/v1.0`

app.listen(3000, () => {
    console.log("Server running on port 3000");
});

app.get("/", async (req, res) => {
    try {
        const response = await axios.get(`${daprBaseUrl}/state/statestore/names`);
        let returnValue = response.data ?? []
        console.log(`Received response ${response.data}.  Returning ${returnValue}`);
        res.json(returnValue);
    }
    catch (error) {
        console.error(error);
        res.status(500);
    }
});

app.post("/", async (req, res) => {
    try {
        console.log(`updating names to ${req.body}`)

        const response = await axios.post(`${daprBaseUrl}/state/statestore`, [
            {
                key: "names",
                value: req.body
            }
        ]);
    
        console.log(response.data);
        res.status(204);
    }
    catch (error) {
        console.error(error);
        res.status(500);
    }

})

