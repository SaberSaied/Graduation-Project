# 🧠 Finance Manager Backend API

A **production-ready backend service** for a personal finance management application, powered by **AI-driven financial insights**.

Built using **Node.js, Express, TypeScript, Prisma, PostgreSQL**, and integrated with **Google Gemini AI**.

---

# 🚀 Overview

This backend provides a complete system for:

- 🔐 Secure Authentication (JWT + Google OAuth2)
- 💰 Income & Expense Tracking
- 🏷 Categories Management
- 📊 Advanced Analytics & Financial Reports
- 🎯 Budgets & Savings Goals
- 🤖 AI Financial Assistant (Chat-based)
- 💱 Multi-Currency Support
- 🔔 Notifications & Alerts

---

# 🏗 Architecture (Feature-Based / Scalable)

```
apps/backend/
├── src/
│   ├── config/        # Env, DB, JWT, Gemini, Logger
│   ├── middleware/    # Auth, Validation, Error handling, Rate limit
│   ├── modules/       # Feature modules (DDD style)
│   │   ├── auth/
│   │   ├── users/
│   │   ├── transactions/
│   │   ├── budgets/
│   │   ├── goals/
│   │   ├── analytics/
│   │   ├── notifications/
│   │   └── ai-chat/
│   ├── services/      # Shared services (AI, currency, email)
│   ├── utils/         # Helpers, validators, formatters
│   ├── types/         # Global TypeScript types
│   └── index.ts       # Entry point
│
├── prisma/            # DB schema, migrations, seed
├── scripts/           # Testing & automation
└── package.json
```

---

# 🛠 Tech Stack

| Layer      | Technology                  |
| ---------- | --------------------------- |
| Runtime    | Node.js                     |
| Framework  | Express.js                  |
| Language   | TypeScript                  |
| ORM        | Prisma                      |
| Database   | PostgreSQL (Neon)           |
| Auth       | JWT + bcrypt + Google OAuth |
| AI         | Google Gemini               |
| Validation | Zod / Custom Middleware     |
| Logging    | Winston                     |
| Security   | Helmet, Rate Limit          |

---

# 🔐 Authentication System

### Supported Methods:

1. **Email / Password (JWT)**
2. **Google OAuth2**

---

## 🔑 Auth Flow

```
Register → Login → Receive JWT → Access Protected APIs
```

### Example:

#### Register

```
POST /api/v1/auth/sign-up/email
```

#### Login

```
POST /api/v1/auth/sign-in/email
```

#### Response:

```json
{
  "token": "JWT_TOKEN",
  "user": {
    "id": "1",
    "email": "user@email.com",
    "name": "User"
  }
}
```

---

# 📦 Core Modules

## 🔐 Auth

- Register / Login
- Google OAuth
- JWT handling

## 👤 Users

- Get profile
- Update user data

## 💰 Transactions

- Create / Read / Delete transactions
- Income & expense tracking

## 🏷 Categories

- Custom categories
- User-defined tags

## 📊 Analytics

- Dashboard insights
- Spending trends
- Savings rate

## 🎯 Goals

- Savings targets
- Progress tracking

## 💸 Budgets

- Monthly limits
- Alerts

## 🔔 Notifications

- Budget alerts
- System reminders

## 🤖 AI Chat

- Financial advice
- Smart suggestions
- Conversation sessions

---

# 🤖 AI Financial Assistant (Gemini)

The system integrates **Google Gemini AI** to:

- Analyze user spending behavior
- Provide financial advice
- Simulate financial scenarios
- Answer user questions in real-time

---

## Example:

```
POST /api/v1/ai/chat
```

```json
{
  "message": "How can I save more money?",
  "sessionId": "optional"
}
```

---

# 📊 Analytics Example

```
GET /api/v1/analytics/dashboard
```

```json
{
  "totalIncome": 5000,
  "totalExpenses": 2500,
  "netSavings": 2500,
  "savingsRate": 50
}
```

---

# 💱 Currency System

- Real-time exchange rates
- Multi-currency support
- External API integration

---

# 🛡 Security

- JWT Authentication
- Rate Limiting
- Input Validation
- Secure Headers (Helmet)
- Email Verification (optional)
- Role-Based Access (extendable)

---

# 🧠 Error Handling

Centralized error system:

```json
{
  "success": false,
  "message": "Validation error"
}
```

---

# ⚙️ Environment Variables

Create `.env`:

```env
DATABASE_URL=
JWT_SECRET=
JWT_EXPIRES_IN=7d

GEMINI_API_KEY=

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

EMAIL_HOST=
EMAIL_PORT=
EMAIL_USER=
EMAIL_PASS=
```

---

# ▶️ Running the Project

```bash
npm install
npm run dev
```

---

# 🗄 Database Setup

```bash
npx prisma migrate dev
npx prisma generate
```

---

# 📡 API Base URL

```
http://localhost:5000/api/v1
```

---

# 🔗 Frontend Integration Guide

### 1. Authenticate

Store JWT from login

### 2. Send Token

```
Authorization: Bearer <token>
```

### 3. Use APIs

- Fetch dashboard
- Create transactions
- Use AI chat
- Manage budgets/goals

---

# 🧪 Testing

```bash
npm test
```

---

# 🐳 Docker (Optional)

```bash
docker-compose up
```

---

# 🚀 Deployment

- Backend → Railway / VPS
- Database → Neon PostgreSQL
- Environment → `.env`

---

# 📈 Future Improvements

- WebSockets (real-time updates)
- Offline sync
- Advanced AI predictions
- Multi-user collaboration

---

# 👨‍💻 Author

**Saber Eldgwy**

**Mahmoud Elsayed**

---

# 🎯 How to Present This Project (Quick Pitch)

> "This is a scalable backend system for a personal finance app,
> designed using modular architecture, with secure authentication,
> real-time financial tracking, and an AI assistant powered by Gemini
> to help users make smarter financial decisions."
