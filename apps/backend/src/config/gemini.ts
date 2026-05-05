import { GoogleGenerativeAI } from '@google/generative-ai';
import { env } from './env';

let genAI: GoogleGenerativeAI | null = null;

export function getGeminiClient(): GoogleGenerativeAI | null {
  if (!env.GEMINI_API_KEY) {
    console.warn('⚠️ GEMINI_API_KEY not set — AI chat will be unavailable');
    return null;
  }

  if (!genAI) {
    genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);
  }

  return genAI;
}

export async function callGemini(
  systemPrompt: string,
  userMessage: string,
  file?: { buffer: Buffer; mimetype: string }
): Promise<string> {
  const client = getGeminiClient();
  if (!client) {
    return 'AI chat is currently unavailable. Please configure the GEMINI_API_KEY.';
  }

  const model = client.getGenerativeModel({
    model: 'gemini-2.5-flash',
    systemInstruction: systemPrompt,
  });

  try {
    const parts: any[] = [userMessage || 'Analyze this file'];

    if (file) {
      parts.push({
        inlineData: {
          data: file.buffer.toString('base64'),
          mimeType: file.mimetype,
        },
      });
    }

    const result = await model.generateContent(parts);
    const response = result.response;
    return response.text();
  } catch (error) {
    console.error('Error calling Gemini API:', error);
    return 'I apologize, but I am currently experiencing technical difficulties processing your request. Please try again later.';
  }
}
