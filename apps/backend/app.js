const axios = require("axios").default;
const express = require("express");
const app = express();
const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const daprBaseUrl = `http://localhost:${daprPort}/v1.0`

app.use(express.json());
app.use(express.urlencoded({ extended: true }))

app.listen(3000, () => {
    console.log("Server running on port 3000");
});

app.get("/", async (req, res) => {
    try {
        const response = await axios.get(`${daprBaseUrl}/state/statestore/names`);
        let returnValue = response.data ?? []
        console.log(`Received the following from dapr state backend ${returnValue}`);
        res.json(returnValue);
    }
    catch (error) {
        console.error(error);
        res.status(500);
    }
});

app.post("/", async (req, res) => {
    try {
        console.log(`Updating names in dapr state backend to ${req.body}`)

        await axios.post(`${daprBaseUrl}/state/statestore`, [
            {
                key: "names",
                value: req.body
            }
        ]);

        res.json(req.body);
    }
    catch (error) {
        console.error(error);
        res.status(500);
    }

})

