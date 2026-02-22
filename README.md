# MaaCare 💕
### *You are never alone, Mama*

A complete Flutter motherhood support app for expectant and new mothers. Available on **Android, iOS, and Web**.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🤱 Onboarding | 3-step setup with confetti animation |
| 🏠 Home Dashboard | Baby week tracker, mood log, tips, gamification |
| 🤖 AI Companion | 24/7 empathetic chat (InsForge AI) |
| 📊 Pregnancy Tracker | Weekly progress, daily tasks (+points), milestones |
| 🌳 Parents Park | Anonymous community forum, likes, week-filter |
| 🩺 Symptom Checker | Risk-leveled symptom selection + doctor CTA |
| 👩‍⚕️ Consult Expert | Doctor cards + Razorpay booking (Android/iOS) |
| 🧘 Self Care | Journal, prenatal yoga, meditation guides |
| 💉 Vaccination Tracker | WHO/India schedule, completion tracking |
| 🍱 Nutrition Guide | Indian recipes + calorie calculator |
| 💜 Family Planning | Fertility tips + contraception comparison |
| 👩 Profile | Points/badges (Super Mom!), settings, language |

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.19+  (`flutter doctor`)
- Dart 3.3+
- Android Studio / Xcode / Chrome

### 1. Get dependencies
```bash
flutter pub get
```

### 2. Set up your API keys
Edit `lib/constants.dart`:
```dart
static const String supabaseUrl      = 'https://89wh46c8.ap-southeast.insforge.app';
static const String supabaseAnonKey  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMTI3MDR9.D4sC4V-O1_n-e_w2-k-y-9-8-7-6-5-4-3-2-1-0-a-b-c-d-e-f-g-h-i-j-k-l-m';
static const String razorpayKey      = 'YOUR_RAZORPAY_KEY_ID';
```

### 3. Backend Setup
The database schema has already been deployed to your **InsForge** project via MCP.

### 4. Add Poppins fonts
Download from [Google Fonts](https://fonts.google.com/specimen/Poppins) and place in `assets/fonts/`:
- `Poppins-Regular.ttf`
- `Poppins-Medium.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`

---

## ▶️ Run Commands

```bash
# Android (device or emulator)
flutter run

# Web (Chrome)
flutter run -d chrome

# iOS (Mac with Xcode required)
flutter run -d ios
```

---

## 📁 Project Structure

```
lib/
├── main.dart                  # Entry point, InsForge init, routes
├── app_theme.dart             # Colors, Poppins theme
├── constants.dart             # API keys, AI prompt, gamification config
├── models/                    # Data classes
├── services/                  # InsForge (REST), AI, Notifications
├── providers/                 # Provider state (User, Chat, Community)
├── screens/                   # 13 feature screens
└── widgets/                   # MaaButton, MoodSelector, MaaCard
```

---

## 🎨 Design System

| Token | Value |
|---|---|
| Primary Pink | `#FFB6C1` |
| Peach | `#FFDAB9` |
| Deep Pink (accent) | `#FF8FAB` |
| Gold | `#FFD700` |
| Font | Poppins (Google Fonts) |
| Card radius | 20px |
| Button radius | 30px |

---

## 🗄️ InsForge Schema

Tables: `users`, `chats`, `posts`, `symptoms`, `vaccinations`  
All tables support RLS and are hosted on your **InsForge** project.

---

## 🧠 Psychology Features

- **Empathy**: AI responses start with "I understand, Mama..." 
- **Social proof**: "1,23,456 Mamas online" banner
- **Gamification**: Points, streak counter, 5 badge tiers
- **Micro-wins**: Instant feedback on tasks and mood logs
- **Anonymity**: Community posts are anonymous by default

---

## ⚠️ Known Limitations

- `razorpay_flutter` does not support Web → payment flow shows informational message on web
- Poppins fonts must be added locally OR you can rely on `google_fonts` network load
- Hindi language support is in progress (English fully supported)

---

## 📝 License

MIT – Made with 💕 for mothers everywhere.
