import { callAI } from './config/ai';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(__dirname, '../.env') });

async function testAI() {
  console.log('--- Testing AI Service ---');
  
  try {
    console.log('Calling AI with a simple prompt...');
    const response = await callAI(
      'You are a helpful assistant.',
      'Hello! Who are you?'
    );
    console.log('AI Response:', response);
  } catch (error: any) {
    console.error('Test failed:', error);
  }
}

testAI();
