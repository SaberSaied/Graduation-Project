import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(__dirname, '../.env') });

async function listModels() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY is not set');
    return;
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  try {
    // There is no direct listModels in the SDK for the web/node client usually
    // But we can try to call a basic model to see what happens
    console.log('Testing gemini-pro...');
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    const result = await model.generateContent('test');
    console.log('gemini-pro works!');
  } catch (error: any) {
    console.error('gemini-pro failed:', error.status, error.statusText);
  }

  try {
    console.log('Testing gemini-1.5-flash...');
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent('test');
    console.log('gemini-1.5-flash works!');
  } catch (error: any) {
    console.error('gemini-1.5-flash failed:', error.status, error.statusText);
  }
}

listModels();
