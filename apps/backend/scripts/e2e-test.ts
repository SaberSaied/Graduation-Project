const BASE_URL = 'http://localhost:3000/api/v1';

const runTests = async () => {
  console.log('🚀 Starting end-to-end backend tests...');

  // 1. Testing Registration
  console.log('\n--- 1. Testing Registration ---');
  const regEmail = `test_${Date.now()}@example.com`;
  
  const regRes = await fetch(`${BASE_URL}/auth/sign-up/email`, {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Origin': 'http://localhost:3000'
    },
    body: JSON.stringify({
      name: 'Test Setup User',
      email: regEmail,
      password: 'password123',
    }),
  });
  
  let token = null;
  if (regRes.status === 201) {
    const regBody = (await regRes.json()) as any;
    token = regBody.token;
    console.log('✅ User registered successfully. Token received in response body.');
  } else {
    console.error('❌ Registration failed:', regRes.status, await regRes.text());
    return;
  }

  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 2. Fetch User Profile
  console.log('\n--- 2. Fetching User Analytics ---');
  const analyticsRes = await fetch(`${BASE_URL}/analytics/dashboard`, {
    headers: defaultHeaders,
  });
  if (analyticsRes.status === 200) {
    console.log('✅ Analytics fetched successfully:', await analyticsRes.json());
  } else {
    console.error('❌ Analytics fetch failed:', analyticsRes.status, await analyticsRes.text());
  }

  // 3. Create Category
  console.log('\n--- 3. Testing Category Creation ---');
  const catRes = await fetch(`${BASE_URL}/categories`, {
    method: 'POST',
    headers: defaultHeaders,
    body: JSON.stringify({
      name: 'Groceries',
      icon: '🛒',
      color: '#FF0000',
      type: 'EXPENSE',
    }),
  });
  
  let categoryId = null;
  if (catRes.status === 201) {
    const catBody = (await catRes.json()) as any;
    categoryId = catBody.data.id;
    console.log('✅ Category created successfully:', catBody.data);
  } else {
    console.error('❌ Category creation failed:', catRes.status, await catRes.text());
    return;
  }

  // 4. Create Transaction
  console.log('\n--- 4. Testing Transaction Creation ---');
  const txRes = await fetch(`${BASE_URL}/transactions`, {
    method: 'POST',
    headers: defaultHeaders,
    body: JSON.stringify({
      categoryId,
      type: 'EXPENSE',
      amount: 150.50,
      currency: 'USD',
      title: 'Weekly Groceries',
      date: new Date().toISOString(),
    }),
  });

  if (txRes.status === 201) {
    console.log('✅ Transaction created successfully:', await txRes.json());
  } else {
    console.error('❌ Transaction creation failed:', txRes.status, await txRes.text());
  }

  // 5. AI Chat
  console.log('\n--- 5. Testing AI Chat Integration ---');
  const aiRes = await fetch(`${BASE_URL}/ai/chat`, {
    method: 'POST',
    headers: defaultHeaders,
    body: JSON.stringify({
      message: 'Give me a summary of my spending.',
    }),
  });

  if (aiRes.status === 200) {
    console.log('✅ AI Response received:', await aiRes.json());
  } else {
    console.error('❌ AI Chat failed:', aiRes.status, await aiRes.text());
  }

  console.log('\n🎉 End-to-End backend test cycle complete!');
}

runTests().catch(console.error);
