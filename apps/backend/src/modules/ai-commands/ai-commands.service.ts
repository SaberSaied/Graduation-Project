import { callAI } from '../../config/ai';
import { prisma } from '../../config/database';
import { AICommandResponse } from './ai-commands.schema';

export async function parseCommand(userId: string, prompt: string): Promise<AICommandResponse> {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  
  const now = new Date();
  
  const systemPrompt = `
You are a highly intelligent financial assistant copilot for the "Finance Manager" app.
Your task is to parse user natural language prompts and extract structured financial actions.
Users can perform multiple actions in a single message.

AVAILABLE ACTIONS:

1. CREATE_CATEGORY:
   - name: string
   - icon: string (emoji)
   - color: string (hex)
   - type: "EXPENSE" | "INCOME"

2. CREATE_TRANSACTION:
   - title: string
   - amount: number
   - type: "EXPENSE" | "INCOME"
   - category: string (name)
   - date: string (ISO date, default now)
   - isRecurring: boolean (default false)
   - recurringInterval: "DAILY" | "WEEKLY" | "MONTHLY" | "YEARLY" (optional)

3. CREATE_GOAL:
   - title: string
   - targetAmount: number
   - deadline: string (ISO date, optional)
   - icon: string (emoji)
   - color: string (hex)
   - autoSaveAmount: number (optional)
   - autoSavePercentage: number (optional)
   - autoSaveFrequency: "DAILY" | "WEEKLY" | "MONTHLY" (optional)

4. CONTRIBUTE_TO_GOAL:
   - goalTitle: string
   - amount: number

5. CREATE_BUDGET (Expense Control):
   - category: string (name)
   - amount: number
   - period: "WEEKLY" | "MONTHLY" | "CUSTOM" (default "MONTHLY")
   - alertThreshold: number (0 to 1, default 0.8)
   - startDate: string (ISO date, required if CUSTOM)
   - endDate: string (ISO date, required if CUSTOM)

6. CREATE_REMINDER:
   - title: string
   - date: string (ISO date)

7. CREATE_NOTE:
   - content: string

OUTPUT FORMAT:
Respond ONLY with a valid JSON object in this exact format (no markdown blocks, no extra text):
{
  "actions": [
    { "type": "ACTION_TYPE", "data": { ... } },
    ...
  ],
  "summary": "A brief user-friendly summary of what will be created."
}

RULES:
- Budgets are strictly for EXPENSES. Goals are for SAVINGS.
- If a category mentioned doesn't exist in the system, you MUST also include a CREATE_CATEGORY action for it BEFORE the action that uses it.
- Today's date is ${now.toISOString()}.
- User's base currency is ${user.currency}.
- Be precise with amounts and dates.
- If the user says "save 1000 for car", it's a CONTRIBUTE_TO_GOAL action for "car".
- If the user says "spent 50 on food", it's a CREATE_TRANSACTION action (type EXPENSE).
- If the user says "budget my entertainment to 300", it's a CREATE_BUDGET action for category "entertainment".
`;

  const responseText = await callAI(systemPrompt, prompt);
  
  // Clean response text in case AI adds markdown
  const cleanJson = responseText.replace(/```json|```/g, '').trim();
  
  try {
    const parsed = JSON.parse(cleanJson);
    return parsed as AICommandResponse;
  } catch (error) {
    console.error('Failed to parse AI response:', cleanJson);
    throw new Error('AI failed to generate a structured response. Please try again with a clearer prompt.');
  }
}
