import { GoogleGenerativeAI } from '@google/generative-ai';
import { env } from './env';

let genAI: GoogleGenerativeAI | null = null;

function getGeminiClient(): GoogleGenerativeAI | null {
  if (!env.GEMINI_API_KEY) {
    console.warn('⚠️ GEMINI_API_KEY not set');
    return null;
  }

  if (!genAI) {
    genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);
  }

  return genAI;
}

async function callGemini(
  systemPrompt: string,
  userMessage: string,
  file?: { buffer: Buffer; mimetype: string }
): Promise<string> {
  const client = getGeminiClient();
  if (!client) throw new Error('Gemini client not configured');

  const model = client.getGenerativeModel({
    model: 'gemini-2.5-flash',
    systemInstruction: systemPrompt,
  });

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
}

async function callOpenRouter(
  systemPrompt: string,
  userMessage: string,
  file?: { buffer: Buffer; mimetype: string }
): Promise<string> {
  if (!env.OPENROUTER_API_KEY) throw new Error('OpenRouter API key not configured');

  const messages: any[] = [
    { role: 'system', content: systemPrompt },
  ];

  if (file) {
    // OpenRouter/Qwen supports image URLs or base64 in a specific format
    const base64Image = file.buffer.toString('base64');
    messages.push({
      role: 'user',
      content: [
        { type: 'text', text: userMessage || 'Analyze this image' },
        {
          type: 'image_url',
          image_url: {
            url: `data:${file.mimetype};base64,${base64Image}`,
          },
        },
      ],
    });
  } else {
    messages.push({ role: 'user', content: userMessage });
  }

  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/SaberSaied/Graduation-Project',
      'X-Title': 'Finance Manager AI',
    },
    body: JSON.stringify({
      model: env.OPENROUTER_MODEL,
      messages,
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`OpenRouter API error: ${JSON.stringify(error)}`);
  }

  const data: any = await response.json();
  return data.choices[0].message.content;
}

async function callGroq(
  systemPrompt: string,
  userMessage: string,
): Promise<string> {
  if (!env.GROQ_API_KEY) throw new Error('Groq API key not configured');

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: env.GROQ_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Groq API error: ${JSON.stringify(error)}`);
  }

  const data: any = await response.json();
  return data.choices[0].message.content;
}

export async function callAI(
  systemPrompt: string,
  userMessage: string,
  file?: { buffer: Buffer; mimetype: string }
): Promise<string> {
  // Try Gemini first
  try {
    if (env.GEMINI_API_KEY) {
      console.log('--- Calling Gemini ---');
      return await callGemini(systemPrompt, userMessage, file);
    }
  } catch (error: any) {
    console.warn('Gemini failed or rate limited, falling back to OpenRouter:', error.message);
  }

  // Fallback 1: OpenRouter
  try {
    if (env.OPENROUTER_API_KEY) {
      console.log('--- Calling OpenRouter (Fallback 1) ---');
      return await callOpenRouter(systemPrompt, userMessage, file);
    }
  } catch (error: any) {
    console.warn('OpenRouter fallback failed, falling back to Groq:', error.message);
  }

  // Fallback 2: Groq (Note: Groq implementation here only supports text)
  try {
    if (env.GROQ_API_KEY) {
      console.log('--- Calling Groq (Fallback 2) ---');
      return await callGroq(systemPrompt, userMessage);
    }
  } catch (error: any) {
    console.error('Groq fallback also failed:', error.message);
  }

  return 'I apologize, but I am currently experiencing technical difficulties. My primary and backup AI systems (Gemini, OpenRouter, and Groq) are all unavailable. Please try again in a moment.';
}
