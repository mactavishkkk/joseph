const express = require('express');
const axios = require('axios');
const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require("@google/generative-ai");

dotenv.config();

const app = express();
const port = 3000;

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

async function helloWorld() {
    const prompt = "Escreve uma mensagem de boas vindas ao projeto joseph. Use apenas uma linha";

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = await response.text();
    return text;
}

app.get('/', async (req, res) => {
    try {
        const message = await helloWorld();
        res.json({ message });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to generate message' });
    }
});

app.listen(port, () => {
    console.log(`Servidor rodando em http://localhost:${port}`);
});
