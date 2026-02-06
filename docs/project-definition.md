# Diskarte AI — Project Definition

## Overview

**Diskarte AI** is a Filipino-focused AI assistant application designed to empower Filipino users with practical, AI-powered tools for everyday challenges — from navigating government bureaucracy to landing a job in the BPO industry. The app is built as a cross-platform (web, Android, iOS) Flutter application backed by Firebase and Google Gemini AI.

**Project ID:** `diskarte-ai`
**Live URL:** https://diskarte-ai.web.app
**Region:** Asia-Southeast1 (Singapore)

---

## Core Features

### 1. Bureaucracy Breaker
Helps users write formal Philippine government documents such as barangay indigency letters, passport inquiry letters, and other official correspondence. Uses formal Filipino/English tone appropriate for government agencies.

### 2. Diskarte Toolkit
A professional communication assistant for job seekers — particularly those targeting the BPO industry. Includes resume writing guidance and professional email/message drafting.

### 3. Aral Masa (Homework Helper)
An educational assistant that explains academic concepts step-by-step in a way that Filipino students can easily understand. Covers a range of subjects with clear, patient explanations.

### 4. Diskarte Coach
A motivational coach that uses Filipino slang and a friendly "Tropa" (buddy) tone to encourage and guide users through personal and professional challenges.

---

## Monetization Model

| Tier | Details |
|------|---------|
| **Free Trial** | 3 messages on the landing page (anonymous auth) |
| **Day Pass** | ₱1 for 24-hour unlimited access (beta pricing) |
| **Payment Methods** | GCash, PayMaya, Card, Grab Pay via PayMongo |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App (Dart)                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │ Landing  │ │   Auth   │ │Dashboard │ │ Admin  │ │
│  │  (Trial) │ │(Phone OTP│ │ (Features│ │(Owner) │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘ │
│       │             │            │            │      │
│       └─────────────┴──────┬─────┴────────────┘      │
│                            │                         │
│              ┌─────────────┴──────────────┐          │
│              │     AI Service Layer       │          │
│              │   (lib/services/ai_service)│          │
│              └─────────────┬──────────────┘          │
└────────────────────────────┼─────────────────────────┘
                             │ HTTPS
┌────────────────────────────┼─────────────────────────┐
│           Firebase Cloud Functions (Node.js/TS)      │
│                            │                         │
│  ┌─────────────┐  ┌───────┴───────┐  ┌───────────┐  │
│  │ callGemini  │  │createCheckout │  │PayMongo   │  │
│  │ (AI endpoint│  │Session        │  │Webhook    │  │
│  └──────┬──────┘  └───────────────┘  └───────────┘  │
│         │                                            │
└─────────┼────────────────────────────────────────────┘
          │ API Call
┌─────────┴──────────┐   ┌─────────────────────┐
│  Google Gemini     │   │  Cloud Firestore    │
│  2.0 Flash API     │   │  (Database + Auth)  │
└────────────────────┘   └─────────────────────┘
```

---

## Tech Stack

### Frontend
| Component | Technology |
|-----------|-----------|
| Language | Dart |
| Framework | Flutter (SDK ^3.10.3) |
| State Management | Provider (v6.1.5) |
| UI System | Material Design 3 |
| HTTP Client | http (v1.6.0) |
| Local Storage | SharedPreferences |
| Markdown Rendering | flutter_markdown |

### Backend
| Component | Technology |
|-----------|-----------|
| Runtime | Node.js 20 |
| Language | TypeScript (^4.9.5) |
| Framework | Firebase Cloud Functions |
| AI Model | Google Gemini 2.0 Flash |
| AI SDK | @google/generative-ai (v0.24.1) |

### Infrastructure
| Component | Technology |
|-----------|-----------|
| Database | Cloud Firestore |
| Authentication | Firebase Auth (Phone + Anonymous) |
| Hosting | Firebase Hosting |
| Error Tracking | Firebase Crashlytics |
| Payments | PayMongo API |

---

## Project Structure

```
diskarte-ai/
│
├── lib/                              # Flutter App Source
│   ├── main.dart                     # App entry point
│   ├── firebase_options.dart         # Firebase config
│   ├── config/
│   │   └── owner_config.dart         # Admin UID
│   ├── services/
│   │   └── ai_service.dart           # Backend communication
│   └── features/
│       ├── landing/                  # Landing page + trial chat
│       ├── auth/                     # Phone login screen
│       ├── dashboard/                # Main dashboard
│       ├── resume/                   # Resume wizard
│       ├── bureaucracy/              # Government docs helper
│       ├── shared/                   # Common widgets
│       └── admin/                    # Admin dashboard
│
├── functions/                        # Cloud Functions Backend
│   ├── src/
│   │   ├── index.ts                  # All cloud functions
│   │   └── prompts.ts               # AI system prompts
│   ├── package.json
│   └── tsconfig.json
│
├── web/                              # Flutter web shell
├── assets/images/                    # App images
├── firestore.rules                   # Database security rules
├── firebase.json                     # Deployment config
└── pubspec.yaml                      # Flutter dependencies
```

---

## Entry Points

### Frontend
**`lib/main.dart`** — Initializes Firebase, sets up Crashlytics error handling, and launches the app with `LandingPageScreen` as the initial route.

### Backend (Cloud Functions)

| Function | Type | Description |
|----------|------|-------------|
| `callGemini` | HTTP | Main AI endpoint — receives user message + feature type, loads system prompt, calls Gemini, saves response to Firestore |
| `createCheckoutSession` | Callable | Creates a PayMongo checkout session for the ₱1 day pass |
| `handlePayMongoWebhook` | HTTP | Receives payment confirmations from PayMongo, activates user subscription |
| `getAdminStats` | HTTP | Returns platform statistics (owner-only) |

---

## User Flow

```
Landing Page (anonymous)
    │
    ├── Try AI chat (3 free messages)
    │       │
    │       └── Limit reached → Prompt to sign up
    │
    └── Sign Up / Login
            │
            ├── Enter phone number
            ├── Receive OTP via SMS
            └── Verify OTP
                    │
                    └── Dashboard
                            │
                            ├── Select Feature
                            │       │
                            │       ├── Bureaucracy Breaker
                            │       ├── Diskarte Toolkit
                            │       ├── Aral Masa
                            │       └── Diskarte Coach
                            │
                            └── Chat with AI
                                    │
                                    ├── (Subscribed) → Unlimited
                                    └── (Not subscribed) → Pay ₱1 day pass
                                            │
                                            └── PayMongo checkout
                                                (GCash / PayMaya / Card)
```

---

## Data Model (Firestore)

```
users/{userId}
├── subscription_end_timestamp    # Firestore Timestamp
├── is_active                     # Boolean
├── last_payment_id               # Idempotency key
├── last_request_timestamp        # Rate limiting
│
└── chat_logs/{featureType}/
    └── messages/{messageId}
        ├── content               # Message text
        ├── sender                # "user" | "ai"
        └── timestamp             # Server timestamp
```

---

## Security

- **Firestore Rules** enforce user-scoped data access — users can only read/write their own documents
- **Subscription fields** are protected from client-side manipulation
- **Cloud Functions** verify Firebase ID tokens on every request
- **Admin endpoints** are gated by owner UID check
- **Rate limiting**: minimum 5-second gap between AI requests
- **PayMongo webhook** signature verification prevents spoofed payments

---

## Deployment

| Target | Command |
|--------|---------|
| Cloud Functions | `firebase deploy --only functions` |
| Firestore Rules | `firebase deploy --only firestore:rules` |
| Web Hosting | `flutter build web && firebase deploy --only hosting` |
| Full Deploy | `firebase deploy` |

---

## Key Configuration

- **Firebase secrets**: `GEMINI_API_KEY`, `PAYMONGO_WEBHOOK_SECRET`
- **Cloud Functions**: 60s timeout, 256MB memory, asia-southeast1 region
- **Theme**: Navy blue (`#002D72`) Material Design 3
- **App Version**: 1.0.0+1

---

*Document generated on 2026-02-06*
