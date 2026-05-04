# 🧠 Finance Manager — Full-Stack AI Personal Finance System

A **production-grade full-stack system** for personal finance management, combining:

- 📱 Cross-platform Mobile App (Flutter)
- 🖥 Backend API (Node.js + Express + TypeScript)
- 🤖 AI Financial Assistant (Google Gemini)
- 📊 Analytics & Insights Engine

---

# 🚀 Project Vision

This system transforms raw financial data into **actionable intelligence**.

Instead of just tracking expenses, it helps users:

- Understand spending behavior
- Improve saving habits
- Get AI-powered financial advice
- Manage budgets and goals efficiently

---

# 🏗 System Architecture

```id="system_arch"
                ┌──────────────────────┐
                │   Mobile App (Flutter)│
                │  - UI / State Mgmt    │
                └─────────┬────────────┘
                          │ REST API
                          ▼
        ┌──────────────────────────────────┐
        │   Backend API (Node.js + TS)     │
        │  - Auth / Business Logic         │
        │  - AI Integration (Gemini)       │
        │  - Analytics Engine              │
        └─────────┬────────────────────────┘
                  │
                  ▼
        ┌──────────────────────────┐
        │ PostgreSQL (Prisma ORM) │
        └──────────────────────────┘
```

---

# 📦 Project Structure

## 🖥 Backend

```id="backend_tree"
apps/backend/
├── src/
│   ├── config/        # App configuration (DB, JWT, AI)
│   ├── modules/       # Feature-based modules
│   ├── services/      # Business logic (AI, currency, analytics)
│   ├── middleware/    # Auth, validation, error handling
│   ├── utils/         # Helpers & utilities
│   └── index.ts
├── prisma/            # Database schema & migrations
└── scripts/
```

---

## 📱 Mobile App

```id="mobile_tree"
apps/mobile/
├── lib/
│   ├── core/          # Shared logic (network, storage, theme)
│   ├── features/      # App features (auth, dashboard, etc.)
│   ├── shared/        # Reusable UI components
│   ├── router/        # Navigation system
│   └── main.dart
```

---

# 🛠 Tech Stack

## Backend

- Node.js
- Express.js
- TypeScript
- Prisma ORM
- PostgreSQL
- JWT Authentication
- Google OAuth2
- Google Gemini AI
- Winston Logger
- Helmet (Security)

---

## Mobile

- Flutter
- Dart
- Riverpod (State Management)
- Dio (Networking)
- Secure Storage
- Material 3 UI

---

# 🔐 Authentication System

Supports:

- Email / Password login
- Google OAuth2
- JWT-based session management

### Flow:

```id="auth_flow"
Register/Login → JWT Token → Secure Storage → API Access
```

---

# 💰 Core Features

## 📊 Transactions

- Add income & expenses
- Categorization system
- Full history tracking

---

## 🏷 Categories

- Custom user categories
- Flexible tagging system

---

## 🎯 Budgets

- Monthly budget tracking
- Overspending alerts

---

## 🎯 Goals

- Savings goals
- Progress tracking

---

## 📊 Analytics

- Spending insights
- Income vs expense comparison
- Financial charts

---

## 🤖 AI Financial Assistant

Powered by **Google Gemini**

### Features:

- Financial advice chat
- Spending analysis
- Smart recommendations

### Example:

```id="ai_example"
User: How can I save money?

AI: You are spending 35% on food. Consider reducing dining expenses...
```

---

## 💱 Currency System

- Multi-currency support
- Live conversion rates

---

## 🔔 Notifications

- Budget alerts
- System reminders

---

# 🧠 AI Engine (Core Innovation)

The AI layer:

- Reads user transactions
- Analyzes spending patterns
- Generates financial insights
- Provides conversational guidance

---

# 🌐 API Design

Base URL:

```id="api_base"
http://localhost:5000/api/v1
```

---

## Main Endpoints

### Auth

- POST `/auth/sign-up`
- POST `/auth/sign-in`

### Transactions

- GET `/transactions`
- POST `/transactions`

### Analytics

- GET `/analytics/dashboard`

### AI Chat

- POST `/ai/chat`

---

# 🧩 Design Principles

- Feature-based architecture
- Separation of concerns
- Scalable module system
- Clean API design
- Reusable UI components

---

# 🛡 Security

- JWT authentication
- Password hashing (bcrypt)
- Rate limiting
- Input validation
- Secure headers (Helmet)

---

# ⚙️ Environment Setup

## Backend `.env`

```env id="env_backend"
DATABASE_URL=
JWT_SECRET=
GEMINI_API_KEY=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

---

# ▶️ Running the Project

## Backend

```bash id="run_backend"
cd apps/backend
npm install
npm run dev
```

---

## Mobile

```bash id="run_mobile_full"
cd apps/mobile
flutter pub get
flutter run
```

---

# 🚀 Key Highlights

- Full-stack production-ready system
- AI-powered financial intelligence
- Scalable architecture
- Cross-platform mobile support
- Clean separation of backend & frontend

---

# 📈 Future Improvements

- Offline-first mode
- Advanced AI predictions
- Push notifications (Firebase)
- Multi-user collaboration

---

# 🎯 Project Summary (Short Pitch)

> This is a full-stack AI-powered finance management system that helps users track, analyze, and optimize their financial behavior using modern mobile technology and intelligent backend services.
