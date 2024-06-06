const { GoogleGenerativeAI } = require("@google/generative-ai");

const dotenv = require('dotenv');

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

async function helloWorld() {
    const prompt = "Escreve uma mensagem de boas vindas ao projeto joseph. Use apenas uma linha";

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = await response.text();
    return text;
}

async function summarizeText(text) {
    const prompt = `Aqui está o texto extraído de um documento PDF:
    
    ${text}
    
    Por favor, extraia os principais tópicos abordados e forneça um resumo detalhado desses tópicos em uma linguagem
    clara e de fácil entendimento.`;

    const result = await model.generateContent(prompt);
    const summary = result.response.text();

    // Processar e formatar a resposta da API
    const data = [];

    const lines = summary.split('\n').filter(line => line.trim() !== '');

    let currentTitle = '';
    let currentResume = '';
    let id = 1;

    lines.forEach(line => {
        if (line.startsWith('**') && line.endsWith('**')) {
            if (currentTitle && currentResume) {
                data.push({ id, title: currentTitle, resume: currentResume });
                id++;
                currentResume = '';
            }
            currentTitle = line.replace(/\*\*/g, '').trim();
        } else {
            currentResume += line.trim() + ' ';
        }
    });

    if (currentTitle && currentResume) {
        data.push({ id, title: currentTitle, resume: currentResume });
    }

    return data;
}

module.exports = {
    helloWorld,
    summarizeText
}