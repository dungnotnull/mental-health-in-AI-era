# How r u bro? — Mental Health in the AI Era

A Flutter mobile app that helps Gen Z track their daily mood, receive AI-powered emotional analysis, share thoughts in a supportive community, and discover mental wellness resources — all with a bro-style Vietnamese vibe.

## Overview

**How r u bro?** is a mental health companion designed for Vietnamese youth navigating life in the age of AI. Users log their daily mood (1-5 scale), describe how they feel, and receive personalized feedback from Grok AI — including a humorous superpower and a practical money tip tailored to their emotional state.

Built with Flutter (Clean Architecture + Riverpod) on the frontend and Supabase (PostgreSQL + Edge Functions) on the backend.

## Key Features

### Mood Tracking with AI Analysis
- Log daily mood with a 1-5 score and free-text feelings
- Grok AI (via Supabase Edge Function) returns:
  - **Super Power**: A funny, imagined ability based on your mood
  - **Money Tip**: A practical or humorous financial advice
- View mood history over time

### Community Feed
- Create, edit, and delete posts
- Like and comment on others' posts
- Supportive bro-style community interactions

### Real-Time Chat
- Direct messaging between users
- WebSocket-powered real-time updates via Supabase Realtime

### Marketplace
- Browse and list mental wellness gigs and services
- Connect with wellness professionals

### Profile & Social
- Customizable user profiles
- Follow/unfollow other users
- Premium subscription support (RevenueCat integration)

### Stats Dashboard
- Visual mood trends and analytics
- Track emotional patterns over time

## Architecture

### Frontend (Flutter)

```
lib/
|-- main.dart                         # App entry point
|-- main_shell.dart                   # Shell with bottom nav
|-- app_router.dart                   # GoRouter configuration
|-- core/
|   |-- common_widgets/               # Reusable widgets (splash, loading, video)
|   |-- navigation/                   # Navigation state (Riverpod)
|   |-- network/                      # Supabase client & Riverpod providers
|   |-- storage/                      # Hive local storage
|   |-- theme/                        # Light/dark theme configuration
|-- features/
    |-- auth/                         # Login, register, forgot password
    |   |-- application/              # AuthController (Riverpod)
    |   |-- data/                     # AuthRepository
    |   |-- domain/                   # AppUser model
    |   |-- presentation/             # Screens + widgets
    |-- chat/                         # Real-time messaging
    |-- daily_mood/                   # Daily mood check-in
    |-- marketplace/                  # Wellness gig listings
    |-- newfeed/                      # Community feed with posts
    |-- post_detail/                  # Post comments and interactions
    |-- profile/                      # User profiles, follows, premium
    |-- stats/                        # Mood analytics dashboard
```

**Tech Stack:**
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Local Storage**: Hive
- **Backend**: Supabase
- **Auth**: Supabase Auth (email/password)
- **Architecture**: Clean Architecture (data/domain/presentation layers)
- **Code Generation**: riverpod_generator, retrofit_generator
- **Theme**: System-aware light/dark mode

### Backend (Supabase)

```
backend/supabase/
|-- config.toml                       # Supabase project configuration
|-- migrations/                       # Database migrations
|-- sql/                              # Raw SQL scripts
|-- functions/
|   |-- grok-mood-analysis/           # Deno Edge Function
|       |-- index.ts                  # Grok AI mood analyzer
|-- init-scripts/                     # Database initialization
|-- storage/                          # File storage buckets
```

**Edge Function: Grok Mood Analysis**

The `grok-mood-analysis` function receives a user's mood score and feeling text, sends it to Grok AI (x.ai), and returns:
- `super_power`: A humorous AI-generated superpower based on the mood
- `money_tip`: A practical financial tip matching the emotional state

Built with Deno and deployed as a Supabase Edge Function.

**Database Topics:**
- Users & profiles
- Mood entries with AI-generated responses
- Posts with likes and comments
- Direct messages (chat)
- Follow relationships
- Marketplace gigs
- Mood statistics

## Features in Detail

| Feature | Status | Description |
|---------|--------|-------------|
| Daily Mood Check-in | Done | 1-5 mood score + text, AI analysis via Grok |
| Mood History | Done | View past mood entries |
| Auth (Login/Register) | Done | Supabase email/password auth with forgot password |
| Newfeed | Done | Create posts, like, comment |
| Chat | Done | Real-time messaging via Supabase Realtime |
| Profile | Done | Edit profile, follow/unfollow |
| Stats Dashboard | Done | Mood trends visualization |
| Marketplace | Done | Browse/list wellness services |
| Dark Mode | Done | System-aware light/dark theme |
| Premium Subscription | Planned | RevenueCat integration for premium features |

## Design Philosophy

The app speaks in **bro** language — casual, friendly, and encouraging Vietnamese. The AI doesn't act like a therapist; it acts like a close friend who's got your back.

Design follows Gen Z aesthetics:
- Animated video backgrounds on auth screens
- Smooth transitions and micro-interactions
- Dark/light mode that adapts to system preference
- Bottom navigation bar for quick feature switching

## Technologies

| Layer | Technology |
|-------|-----------|
| Frontend Framework | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Storage | Hive |
| Backend | Supabase (PostgreSQL) |
| Real-time | Supabase Realtime (WebSocket) |
| Authentication | Supabase Auth |
| AI Integration | Grok AI (x.ai) via Supabase Edge Functions |
| Edge Runtime | Deno |
| Code Generation | riverpod_generator, json_serializable, retrofit_generator |
| In-app Purchases | RevenueCat (planned) |

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Dart 3.5+
- Supabase project (local or cloud)
- Grok AI API key (x.ai)

### Setup

```bash
# Clone the repository
git clone https://github.com/dungnotnull/mental-health-in-AI-era.git
cd toi_van_on_mvp

# Install Flutter dependencies
cd frontend
flutter pub get

# Create .env file in frontend directory
echo SUPABASE_URL=your_supabase_url > .env
echo SUPABASE_ANON_KEY=your_anon_key >> .env

# Run the app
flutter run
```

### Backend Setup

```bash
cd backend/supabase

# Install Supabase CLI and start local development
supabase start

# Apply migrations
supabase db reset

# Set Grok API key for edge function
supabase secrets set GROK_API_KEY=xai-your-key-here

# Deploy edge function
supabase functions deploy grok-mood-analysis
```

## Project Structure

```
toi_van_on_mvp/
|-- frontend/                          # Flutter mobile application
|   |-- lib/
|   |   |-- main.dart                  # App entry with Supabase & Hive init
|   |   |-- app_router.dart            # Route definitions
|   |   |-- core/                      # Shared infrastructure
|   |   |-- features/                  # Feature modules (Clean Arch)
|   |-- assets/                        # Videos, images, quotes
|   |-- android/                       # Android platform files
|   |-- pubspec.yaml                   # Flutter dependencies
|   |-- .env                           # Environment variables (gitignored)
|-- backend/
|   |-- supabase/
|       |-- config.toml                # Supabase configuration
|       |-- migrations/                # SQL migrations
|       |-- functions/                 # Edge Functions
|       |   |-- grok-mood-analysis/    # AI mood analyzer (Deno)
|       |-- sql/                       # SQL utility scripts
|       |-- storage/                   # Storage bucket config
|-- .gitignore
|-- README.md
```

## Why This Matters

In the AI era, Gen Z faces unprecedented mental health challenges — information overload, job displacement anxiety, and social media pressure. **How r u bro?** provides:

- **Low-friction mental health check-ins** — just a mood score and a few words
- **AI as a friend, not a doctor** — playful responses that reduce stigma
- **Community support** — shared experiences in a safe space
- **Practical wellness** — AI-generated tips that are actionable, not clinical

## License

This project is for educational and personal use purposes.
