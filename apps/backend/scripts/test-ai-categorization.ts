const BASE_URL = 'http://localhost:3000/api/v1';

const testAICategorization = async () => {
  console.log('🚀 Starting AI Auto-Categorization tests...');

  // 1. Registration/Login to get token
  const regEmail = `ai_test_${Date.now()}@example.com`;
  const regRes = await fetch(`${BASE_URL}/auth/sign-up/email`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'AI Test User',
      email: regEmail,
      password: 'password123',
    }),
  });
  
  if (regRes.status !== 201) {
    console.error('❌ Registration failed:', regRes.status, await regRes.text());
    return;
  }
  const regBody = (await regRes.json()) as any;
  const token = regBody.token;
  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  const messages = [
    "I spent 250 on Uber.",
    "Paid Netflix subscription.",
    "Received freelance payment 3000.",
    "Bought groceries for 500.",
    "Spent 100 on Space X ticket."
  ];

  for (const message of messages) {
    console.log(`\n💬 Testing message: "${message}"`);
    const aiRes = await fetch(`${BASE_URL}/ai/chat`, {
      method: 'POST',
      headers: defaultHeaders,
      body: JSON.stringify({ message }),
    });

    if (aiRes.status === 200) {
      const data = await aiRes.json();
      console.log('✅ AI Response:', data.message);
      if (data.action) {
        console.log('📊 Action detected:', JSON.stringify(data.action, null, 2));
      } else {
        console.log('⚠️ No action detected.');
      }
    } else {
      console.error('❌ AI Chat failed:', aiRes.status, await aiRes.text());
    }
  }

  // Verify categories created
  console.log('\n--- Verifying Categories ---');
  const catRes = await fetch(`${BASE_URL}/categories`, { headers: defaultHeaders });
  const catData = await catRes.json();
  console.log('All categories:', catData.data.all.map((c: any) => `${c.name} (${c.icon})`).join(', '));

  console.log('\n🎉 AI Auto-Categorization tests complete!');
};

testAICategorization().catch(console.error);
