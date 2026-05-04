# 📱 Finance Manager Mobile App

A **cross-platform mobile application** for personal finance management, built with **Flutter**, powered by a robust backend API and enhanced with an **AI financial assistant**.

---

# 🚀 Overview

This mobile app allows users to:

- 🔐 Authenticate securely (Email / Google)
- 💰 Track income & expenses
- 📊 View financial analytics & reports
- 🎯 Manage budgets & savings goals
- 🤖 Chat with an AI financial assistant
- 🔔 Receive notifications & alerts
- 💱 Work with multiple currencies

---

# 🏗 Architecture (Clean + Scalable)

The app follows a **feature-first + layered architecture**:

```id="mobile_structure"
apps/mobile/
├── lib/
│   ├── core/              # Global app logic
│   │   ├── constants/     # Colors, API endpoints
│   │   ├── theme/         # App theme & styles
│   │   ├── network/       # Dio client & interceptors
│   │   ├── storage/       # Secure storage & cache
│   │   ├── utils/         # Formatters & validators
│   │   ├── errors/        # Exception & failure models
│   │   └── models/        # Shared data models
│   │
│   ├── features/          # Feature-based modules
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── transactions/
│   │   ├── budgets/
│   │   ├── goals/
│   │   ├── analytics/
│   │   ├── notifications/
│   │   ├── ai_chat/
│   │   └── settings/
│   │
│   ├── shared/            # Reusable UI components
│   │   └── widgets/
│   │
│   ├── router/            # Navigation config
│   ├── app.dart           # Root widget
│   └── main.dart          # Entry point
```

---

# 🛠 Tech Stack

| Layer            | Technology                   |
| ---------------- | ---------------------------- |
| Framework        | Flutter 3.x                  |
| Language         | Dart                         |
| State Management | Riverpod                     |
| Networking       | Dio                          |
| Storage          | Secure Storage + Local Cache |
| Routing          | Custom Router                |
| Backend API      | REST API (Node.js)           |
| AI Integration   | Google Gemini                |

---

# 🎨 UI/UX System

- 🎯 Consistent Design System (Colors, Typography)
- 🧩 Reusable Components (Buttons, Inputs, Dialogs)
- 🔄 Loading, Error, Empty States handled globally
- 🌙 Theme-ready (Light/Dark extendable)

---

# 🔐 Authentication Flow

### Supported:

- Email / Password
- Google Sign-In

---

## 🔄 Flow:

```id="auth_flow_mobile"
Login/Register → Receive Token → Store Securely → Access APIs
```

---

# 🌐 Networking Layer

Built using **Dio + Interceptors**

### Features:

- Base API configuration
- JWT auto-injection
- Error handling
- Request/response logging

---

## Example Header:

```id="auth_header_mobile"
Authorization: Bearer <token>
```

---

# 💾 Storage System

- 🔐 Secure Storage → JWT tokens
- ⚡ Local Cache → App data

---

# 🧠 Core Features

## 🏠 Dashboard

- Financial summary
- Quick insights
- Recent transactions

---

## 💰 Transactions

- Add / View / Delete transactions
- Categorized expenses
- Real-time updates

---

## 📊 Analytics

- Charts & reports
- Spending trends
- Savings rate

---

## 🎯 Goals

- Create savings goals
- Track progress visually

---

## 💸 Budgets

- Monthly budget limits
- Alerts on overspending

---

## 🔔 Notifications

- Budget alerts
- System reminders

---

## 🤖 AI Chat Assistant

- Conversational interface
- Financial advice
- Smart recommendations

---

### Example:

```id="ai_chat_mobile"
User: "How can I reduce my expenses?"
AI: "You are spending 30% on food. Consider reducing..."
```

---

# 🧭 Navigation System

- Centralized routing
- Scalable navigation structure
- Supports deep linking (extendable)

---

# ⚙️ Configuration

## API Endpoint

```id="api_base_mobile"
http://localhost:5000/api/v1
```

Update in:

```id="api_constants_path"
lib/core/constants/api_constants.dart
```

---

# ▶️ Running the App

```bash id="run_mobile"
flutter pub get
flutter run
```

---

# 📦 Build Targets

- 📱 Android (APK / AAB)
- 🍎 iOS (IPA)
- 🌐 Web
- 💻 Desktop (Windows / macOS / Linux)

---

# 🔗 Backend Integration

The app communicates with the backend via REST APIs:

- Auth → `/auth`
- Transactions → `/transactions`
- Analytics → `/analytics`
- AI Chat → `/ai-chat`

---

# 🛡 Error Handling

- Centralized error models
- UI-level error display
- Graceful fallbacks

---

# 🧪 Testing (Extendable)

- Unit tests (planned)
- Widget tests (planned)
- Integration tests (planned)

---

# 🚀 Deployment

- Android → Play Store
- iOS → App Store
- Backend required for full functionality

---

# 📈 Future Improvements

- Offline mode (local sync)
- Push notifications (Firebase)
- Real-time updates
- Dark mode toggle
- Advanced charts

---

# 👨‍💻 Author

**Ahmed Ayman**

**Moaaz Ehab**

---

# 🎯 How to Present This App (Quick Pitch)

> "This is a cross-platform mobile application built with Flutter,
> connected to a scalable backend, providing users with full control
> over their finances, enhanced by an AI assistant that delivers
> personalized financial insights."
