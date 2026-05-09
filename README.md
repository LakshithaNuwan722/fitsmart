# 🏋️ FitSmart - AI-Powered Fitness & Meal Planner

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange?style=for-the-badge&logo=firebase)
![Gemini AI](https://img.shields.io/badge/Gemini-AI%20Powered-green?style=for-the-badge&logo=google)
![Android](https://img.shields.io/badge/Android-Available-brightgreen?style=for-the-badge&logo=android)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**An intelligent fitness companion that uses AI to track your meals, generate personalized workouts, and analyze your progress.**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Setup](#-setup) • [AI Features](#-ai-features) • [Architecture](#-architecture)

</div>

---

## 📱 Overview

FitSmart is a cross-platform Flutter mobile application that helps users achieve their fitness goals through the power of Artificial Intelligence. The app combines Google's Gemini AI with Firebase to deliver personalized nutrition tracking and workout planning.

---

## ✨ Features

### 🤖 AI-Powered Features

| Feature | Description |
|---------|-------------|
| 📸 **AI Food Scanner** | Snap a photo of any meal → AI identifies food items → instant nutrition data |
| 💪 **AI Workout Generator** | Creates personalized workout plans based on your profile, goals & history |

### 📊 Core Features

- **Smart Dashboard** - Calorie ring, daily summary, quick actions
- **Meal Tracking** - AI scan or manual entry with full nutrition data
- **Workout Logging** - AI-generated or manual workouts with active timer
- **Progress Analytics** - Charts, BMI tracking, milestones
- **Water Tracker** - Daily hydration monitoring
- **Profile Management** - Personal stats, goals, weight logging
- **Export Reports** - PDF & CSV export (Premium)
- **Subscription System** - Freemium model with premium upgrades

---

## 🆓 Free vs ⭐ Premium

| Feature | Free | Premium |
|---------|------|---------|
| AI Food Scans | 3/day | ✅ Unlimited |
| AI Workouts | 2/day | ✅ Unlimited |
| Meal Tracking | ✅ | ✅ |
| Workout Logging | ✅ | ✅ |
| Basic Analytics | ✅ | ✅ |
| Water Tracker | ✅ | ✅ |
| Nutrition Analytics | ❌ | ✅ |
| Body Metrics & BMI | ❌ | ✅ |
| Goal Progress | ❌ | ✅ |
| Milestones | ❌ | ✅ |
| Export PDF/CSV | ❌ | ✅ |
| Ad-Free | ❌ | ✅ |

---

## 🛠️ Tech Stack

```
┌──────────────────────────────────────────────────┐
│                  TECH STACK                      │
├─────────────────┬────────────────────────────────┤
│ Framework       │ Flutter 3.41.5 (Dart)          │
├─────────────────┼────────────────────────────────┤
│ Backend         │ Firebase (Auth, Firestore,      │
│                 │ Storage)                        │
├─────────────────┼────────────────────────────────┤
│ AI              │ Google Gemini API               │
│                 │ (Vision + Pro models)           │
├─────────────────┼────────────────────────────────┤
│ State Management│ Flutter Riverpod               │
├─────────────────┼────────────────────────────────┤
│ Charts          │ fl_chart                        │
├─────────────────┼────────────────────────────────┤
│ Animations      │ flutter_animate                 │
├─────────────────┼────────────────────────────────┤
│ PDF Export      │ pdf + printing                  │
├─────────────────┼────────────────────────────────┤
│ CSV Export      │ csv                             │
├─────────────────┼────────────────────────────────┤
│ Payments        │ in_app_purchase                 │
├─────────────────┼────────────────────────────────┤
│ Fonts           │ Google Fonts (Inter)            │
└─────────────────┴────────────────────────────────┘
```

---

## 🤖 AI Features

### 📸 Food Recognition (Gemini Vision API)

```
User takes photo
      │
      ▼
Gemini Vision analyzes image
      │
      ▼
Returns JSON with food items:
{
  "foods": [
    {
      "name": "Chicken Rice",
      "quantity": 1,
      "unit": "plate",
      "calories": 550,
      "protein": 28,
      "carbs": 65,
      "fat": 18
    }
  ]
}
      │
      ▼
User confirms & saves to Firestore
```

### 💪 Workout Generator (Gemini Pro API)

```
User profile sent to Gemini:
├── Age, gender, height, weight
├── Fitness goal
├── Activity level
├── Recent workout history
├── Selected focus area
└── Available equipment
      │
      ▼
Gemini generates personalized plan:
├── Workout name & type
├── Warm-up exercises
├── Main exercises (sets/reps/weight)
├── Cool-down exercises
└── Trainer tips
      │
      ▼
User starts workout with timer
```

---

## 📂 Project Structure

```
lib/
├── main.dart                           # App entry point
├── app.dart                            # MaterialApp + theme
│
├── config/
│   ├── theme.dart                      # App theme & colors
│   └── api_keys.dart                   # ⚠️ Not in repo
│
├── models/
│   ├── user_profile.dart               # User data model
│   ├── food_item.dart                  # Food item model
│   ├── meal.dart                       # Meal model
│   ├── exercise.dart                   # Exercise model
│   ├── workout.dart                    # Workout model
│   ├── daily_log.dart                  # Daily log model
│   └── subscription.dart              # Subscription model
│
├── services/
│   ├── auth_service.dart               # Firebase Auth
│   ├── meal_service.dart               # Meal CRUD
│   ├── workout_service.dart            # Workout CRUD
│   ├── progress_service.dart           # Progress data
│   ├── subscription_service.dart       # Subscription management
│   ├── billing_service.dart            # Google Play billing
│   ├── export_service.dart             # PDF/CSV export
│   ├── food_recognition_service.dart   # AI food scanning
│   └── workout_ai_service.dart         # AI workout generation
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── onboarding_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   ├── meals/
│   │   ├── meals_tab.dart
│   │   ├── scan_meal_screen.dart       # 🤖 AI Feature 1
│   │   └── add_meal_screen.dart
│   ├── workouts/
│   │   ├── workouts_tab.dart
│   │   ├── generate_workout_screen.dart # 🤖 AI Feature 2
│   │   └── active_workout_screen.dart
│   ├── profile/
│   │   ├── profile_tab.dart
│   │   ├── progress_screen.dart
│   │   └── export_screen.dart
│   └── subscription/
│       └── paywall_screen.dart
│
├── widgets/
│   └── water_tracker.dart
│
└── utils/
    └── calorie_calculator.dart         # BMR/TDEE formulas
```

---

## 🗄️ Database Schema

```
Firestore Structure:

users/ {userId}
├── name, email, age, gender
├── height, weight
├── goal, activityLevel
├── dailyCalorieTarget
├── subscriptionPlan, subscriptionExpiry
│
├── meals/ {mealId}
│   ├── date, mealType
│   ├── foodItems[]
│   ├── totalCalories, protein, carbs, fat
│   └── timestamp
│
├── workouts/ {workoutId}
│   ├── date, name, type
│   ├── exercises[]
│   ├── duration, caloriesBurned
│   ├── isAIGenerated, completed
│   └── timestamp
│
└── dailyLogs/ {date}
    ├── caloriesConsumed
    ├── caloriesBurned
    ├── waterIntake
    ├── weight
    └── workoutsCompleted
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│                FLUTTER APP                  │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐  │
│  │   Auth   │ │  Meals   │ │  Workouts  │  │
│  └────┬─────┘ └────┬─────┘ └─────┬──────┘  │
│       │             │             │         │
│  ┌────▼─────────────▼─────────────▼──────┐  │
│  │           Services Layer              │  │
│  │  Auth | Meal | Workout | Progress     │  │
│  └────┬──────────────────────────┬───────┘  │
└───────┼──────────────────────────┼──────────┘
        │                          │
   ┌────▼──────┐            ┌──────▼──────┐
   │ Firebase  │            │  Gemini AI  │
   │ Firestore │            │   Vision    │
   │ Auth      │            │   Pro       │
   │ Storage   │            └─────────────┘
   └───────────┘
```


## 🗓️ Development Timeline

| Week | Features Implemented |
|------|---------------------|
| Week 1 | Auth, Onboarding, Dashboard shell |
| Week 2 | AI Food Scanner + Meal Tracking |
| Week 3-4 | AI Workout Generator + Active Timer |
| Week 5-6 | Progress Analytics + Profile + Water Tracker |
| Week 7 | Subscription System + Paywall |
| Week 8 | Professional UI Redesign with animations |
| Week 9 | Advanced Analytics + Export Reports |
| Week 10 | Final Polish + Production Build |

---


## 👤 Author

**Lakshitha**

- GitHub: [@Lakshitha Wijekoon](https://github.com/LakshithaNuwan722)
- LinkedIn: [Lakshitha Wijekoon](www.linkedin.com/in/lakshitha-wijekoon-612b70357)
- Email: lakshithanuwan722@gmail.com

---

## 🙏 Acknowledgments

- [Google Gemini AI](https://ai.google.dev/) - Powerful AI capabilities
- [Firebase](https://firebase.google.com/) - Backend infrastructure
- [Flutter](https://flutter.dev/) - Amazing cross-platform framework
- [fl_chart](https://pub.dev/packages/fl_chart) - Beautiful charts library

---

<div align="center">

**⭐ Star this repo if you found it helpful!**

Built with ❤️ using Flutter & Google Gemini AI

</div>
