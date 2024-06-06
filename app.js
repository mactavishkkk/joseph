const express = require('express');
const { helloWorld, summarizeText } = require('./src/models/gemini');
const { extractTextFromPDF } = require('./src/models/pdf');

const app = express();
const port = 3000;

app.get('/', async (req, res) => {
    try {
        const message = await helloWorld();
        res.json({ message });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to generate message' });
    }
});

let climateChangeAmazon = './assets/docs/amazonia-clima.pdf';

app.get('/api/v1/articles/climate-change-amazon', async (req, res) => {
    try {
        const text = await extractTextFromPDF(climateChangeAmazon);
        const summary = await summarizeText(text);
        res.json({ summary });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to process PDF' });
    }
});

let brazil2024 = './assets/docs/brasil-2040-clima.pdf';

app.get('/api/v1/articles/brazil-2024', async (req, res) => {
    try {
        const text = await extractTextFromPDF(brazil2024);
        const summary = await summarizeText(text);
        res.json({ summary });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to process PDF' });
    }
});

app.listen(port, () => {
    console.log(`Servidor rodando em http://localhost:${port}`);
});
