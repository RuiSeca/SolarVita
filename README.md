# SolarVita - Sustainable Fitness & Wellness Platform

![Flutter](https://img.shields.io/badge/Flutter-3.6+-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Full_Stack-FFCA28?logo=firebase)
![AI Powered](https://img.shields.io/badge/AI-Google_Gemini_1.5-4285F4?logo=google)
![Languages](https://img.shields.io/badge/Languages-11-green)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)

## 🌱 Overview

SolarVita is a production-grade Flutter application that uniquely combines **personal fitness tracking** with **environmental sustainability**. Built with Flutter 3.6+ and a comprehensive Firebase backend, the app motivates users to maintain healthy lifestyles while being mindful of their carbon footprint and environmental impact.

### Core Philosophy

- **Fitness + Sustainability**: Track workouts, nutrition, and eco-friendly activities in one platform
- **AI-Powered Coaching**: Personalized guidance using Google Gemini 1.5 for workouts, meals, and eco tips
- **Community-Driven**: Social features including tribes, challenges, and real-time chat for motivation
- **Privacy-First**: Tiered privacy controls with friends-only defaults and granular data sharing options
- **Global Reach**: 11-language internationalization for worldwide accessibility

---

## ✨ Key Features

### 🤖 AI-Powered Personal Coaching

- **Google Gemini 1.5 Integration** for intelligent, context-aware responses
- **AI Avatar Store** with customizable personalities and coin-based economy
- Personalized workout recommendations based on fitness level and goals
- AI-driven meal planning with dietary preference support
- Eco-friendly lifestyle suggestions tailored to user habits
- Multi-modal food recognition using Google Vision API
- **Rate limiting** with free tier and premium membership system
- Response caching for optimized performance

### 🏋️ Comprehensive Fitness Tracking

- **50+ exercise routines** with animated GIF demonstrations
- Real-time workout logging with sets, reps, weights, and duration
- Personal records (PRs) tracking and progress analytics
- Exercise database with muscle group and equipment filtering
- Difficulty progression from beginner to professional levels
- Custom routine creation and saving
- Workout history with detailed metrics and charts

### 🥗 Advanced Nutrition Management

- **Nutritionix API integration** for comprehensive food database (680k+ foods)
- AI-powered food recognition via camera (Google Vision)
- Weekly meal planning (breakfast, lunch, dinner, snacks)
- Calorie and macro tracking with detailed analytics
- Dietary preferences and allergen management
- Restaurant menu item search
- Barcode scanning for packaged foods

### 🌍 Sustainability & Environmental Impact

- **Carbon footprint tracking** with CO2 savings metrics
- Eco-friendly activity logging (cycling, carpooling, public transport)
- Sustainability score (0-100 rating) based on user actions
- Plastic bottle reduction tracking
- **6 sustainability goal categories**:
  - Carbon footprint reduction
  - Eco-friendly workouts
  - Active transportation
  - Waste reduction
  - Sustainable nutrition
  - Energy conservation
- Educational eco tips categorized by waste, energy, water, and transport

### 👥 Social & Community Features

#### Bidirectional Supporter System

SolarVita features a sophisticated **bidirectional supporter system**:

```
🤝 Supporters (Mutual Support) ↔ 👤 Supporting (One-way Support)
```

- **Mutual Supporters**: Users who have accepted support relationships
- **Supporting**: One-way support relationships (like Twitter/Instagram following)
- Independent control for each user
- Real-time updates when relationships change

#### Real-Time Chat System

- **Private messaging** between supporters with Firebase Realtime Database
- Instant message delivery and read receipts
- Conversation history and search
- Offline message caching and synchronization
- Push notifications for new messages
- Privacy controls and blocking capabilities

#### Enhanced Supporter Profiles

- Comprehensive profile views with privacy controls
- **Granular data sharing**:
  - Weekly progress summaries
  - Daily goals and achievements
  - Meal sharing (when privacy allows)
  - Workout routines and progress
- Direct messaging integration
- Progress comparison features

#### Tribes Community System

- **Interest-based community groups** for specialized discussions
- Tribe creation and moderation tools
- Tribe-specific posts and content
- Member discovery and interaction
- Challenge integration within tribes
- Categories: Fitness focus, sustainability goals, dietary preferences

#### Community Challenges

- **Public participation** for motivation and competition
- Progress tracking with real-time leaderboards
- Challenge types: Fitness goals, sustainability targets
- Time-based: Weekly, monthly challenges
- Participant counts and rankings

### 🎨 User Experience Excellence

- **Lottie-based animated splash screen** that plays even during phone calls
- **Dynamic theming**: Light and dark mode support with Material Design 3
- **11-language localization**: EN, ES, PT, FR, IT, DE, ZH, JA, RU, HI, KO
- **Offline-first architecture** with SharedPreferences caching
- **Smooth animations** and intuitive navigation
- **Accessibility features** throughout the app
- **Custom logo and branding** with adaptive icons for both platforms

---

## 🏗️ Technical Architecture

### Tech Stack

```
Frontend:
├── Flutter 3.6+ (Dart SDK 3.0+)
├── Provider + Riverpod (State Management)
├── Material Design 3 (Dynamic Theming)
├── Lottie Animations (Splash & Loading)
└── Rive Animations (Interactive Elements)

Backend:
├── Firebase Authentication (Google, Facebook, Email, Apple)
├── Cloud Firestore (NoSQL Database)
├── Firebase Cloud Functions (Serverless Backend)
├── Firebase Realtime Database (Chat & Real-time Features)
├── Firebase Storage (Media Assets)
└── Firebase Messaging (Push Notifications)

APIs & Services:
├── Google Gemini 1.5 Pro/Flash (AI Coaching)
├── Nutritionix API (Nutrition Data - 680k+ foods)
├── Google Vision API (Food Recognition)
├── ExerciseDB (Workout Library)
└── Health Connect (Android) / HealthKit (iOS)

Security & Payments:
├── Firebase App Check (Security)
├── Encrypt Package (Chat Encryption)
├── Flutter Secure Storage (Sensitive Data)
├── Google Pay & Apple Pay Integration
└── In-App Purchases (Membership System)
```

### State Management Architecture

- **Provider**: Global state for authentication, user profiles, themes, and language
- **Riverpod**: Complex state management for:
  - Exercise tracking and logging
  - AI responses and avatar system
  - Social features and real-time chat
  - Scroll position memory across tabs
- **SharedPreferences**: Local caching for settings, offline data, and performance
- **Firebase Realtime Listeners**: Live updates for chat, challenges, and social interactions
- **Offline Cache Manager**: User data caching for account switching and offline support

### Performance Optimizations

- **Response caching** for AI interactions to reduce API calls
- **Lazy loading** for exercise library and media content
- **Image optimization** with `cached_network_image`
- **Offline-first architecture** for core features
- **Efficient state management** to minimize rebuilds
- **Structured logging** with Logger package for debugging
- **Async patterns** for non-blocking UI operations
- **Background sync** for automatic data synchronization

### Project Structure

```
lib/
├── main.dart                 # App entry point with dependency injection
├── config/
│   ├── api_config.dart      # API keys and endpoints
│   └── firebase_options.dart
├── i18n/                     # 11-language translation files
│   ├── app_localizations.dart
│   └── translation_helper.dart
├── models/
│   ├── user/
│   │   └── user_profile.dart         # User data model
│   ├── exercise_log.dart             # Workout tracking
│   ├── social_activity.dart          # Community posts
│   ├── friendship.dart               # Social connections
│   ├── follow.dart                   # Bidirectional support system
│   ├── privacy_settings.dart         # Privacy controls
│   ├── community_challenge.dart      # Challenge data
│   ├── conversation.dart             # Chat conversations
│   └── message.dart                  # Chat messages
├── providers/
│   ├── riverpod/
│   │   ├── auth_provider.dart
│   │   ├── user_profile_provider.dart
│   │   ├── theme_provider.dart
│   │   ├── language_provider.dart
│   │   ├── scroll_controller_provider.dart
│   │   ├── splash_provider.dart
│   │   └── initialization_provider.dart
├── screens/
│   ├── dashboard/           # Home feed with stats and community
│   ├── search/              # Exercise discovery
│   ├── health/              # Nutrition & fitness tracking
│   │   └── meals/           # Meal planning and logging
│   ├── ai_assistant/        # Gemini AI chat
│   ├── profile/             # User settings & achievements
│   │   └── settings/        # Comprehensive settings screens
│   ├── chat/                # Real-time messaging
│   ├── avatar_store/        # AI avatar marketplace
│   ├── tribes/              # Community groups
│   ├── social/              # Enhanced social features
│   ├── onboarding/          # First-time user experience
│   └── login/               # Authentication
├── services/
│   ├── auth/                # Authentication services
│   ├── ai/                  # Gemini API integration
│   ├── chat/                # Real-time messaging & data sync
│   ├── database/            # Social, tribes, profiles, notifications
│   ├── meal/                # Nutrition with eco-integration
│   ├── exercises/           # Workout services
│   ├── store/               # Coins and avatar economy
│   ├── user/                # Offline cache, location, strikes
│   ├── translation/         # Firebase translation service
│   └── firebase/            # Firebase initialization
├── widgets/
│   ├── common/              # Reusable UI components
│   ├── splash/              # Lottie splash screen
│   └── [feature-specific widgets]
├── theme/
│   └── app_theme.dart       # Design system & theming
└── utils/
    └── translation_helper.dart  # Internationalization utilities
```

---

## 🔒 Privacy & Security Features

### Privacy-Tiered Social System

```
🔒 Supporters Only (Default) → 🌍 Community → 🌐 Public
```

### Granular Privacy Controls

#### Social Privacy

- **Default post visibility**: Supporters-only (most private)
- **Profile discovery settings**: Show/hide in search
- **Selective data sharing toggles**:
  - Workout statistics
  - Nutrition data (private by default)
  - Eco score and sustainability metrics
  - Achievements and badges
  - Challenge participation

#### App Privacy Settings

- **Data collection controls**: Usage analytics, crash reporting
- **Location tracking**: Optional for location-based features
- **Marketing preferences**: Email communications
- **Security features**: Biometric auth, app lock options
- **GDPR compliance**: Data export and deletion rights

### Security Features

- Firebase Authentication with multiple OAuth providers
- Secure data storage with Firestore security rules
- Chat message encryption with `encrypt` package
- Sensitive data protection with `flutter_secure_storage`
- Firebase App Check for backend security
- No sensitive data sent to AI services without consent
- Secure payment processing with Google Pay & Apple Pay

---

## 📱 Main Navigation

### 5-Tab Bottom Navigation

```
🏠 Dashboard  → Personal fitness hub and community feed
🔍 Search     → Exercise discovery with filtering
💚 Health     → Nutrition and workout tracking
🤖 Solar AI   → AI assistant with avatar customization
👤 Profile    → User settings, achievements, and social
```

### Feature Highlights by Tab

#### 🏠 Dashboard

- Profile header with quick actions
- Support requests notification
- Personal statistics (ModernStatsRow)
- Popular workouts carousel
- Quick exercise routines
- Fitness categories
- Community activity feed (supporters + community)
- Active challenges with leaderboards

#### 🔍 Search

- Exercise database with muscle group filtering
- Activity categories: Strength, Cardio, HIIT, Yoga, Calisthenics
- Equipment filtering: Bodyweight, Dumbbells, Barbells, etc.
- Difficulty levels: Beginner to Professional
- Animated GIF demonstrations

#### 💚 Health

**Nutrition Tracking:**

- Weekly meal planning interface
- AI food recognition
- Nutritionix database integration
- Calorie and macro analytics

**Fitness Tracking:**

- Exercise logging with detailed metrics
- Personal records (PRs) tracking
- Progress charts and analytics
- Workout history

#### 🤖 Solar AI

- Google Gemini 1.5 chat interface
- AI Avatar Store with customization
- Coin-based economy system
- Membership tiers (free/premium)
- Multi-modal capabilities (text + image)
- Personalized responses using profile data

#### 👤 Profile

- Personal achievements showcase
- Quick actions: Add Supporter, View Lists
- Comprehensive settings:
  - Membership management
  - Account settings
  - Notification preferences
  - Privacy controls (social + app)
  - Workout preferences
  - Dietary preferences
  - Sustainability goals
  - Language and theme
  - Help & support

---

## 📊 Firebase Collections Architecture

```
users/                          # User profiles and preferences
├── {userId}/
    ├── profile                # Name, photo, bio
    ├── preferences            # Workout, dietary, sustainability goals
    ├── privacy_settings       # Social and app privacy controls
    ├── achievements           # Unlocked badges and milestones
    ├── coins                  # Virtual currency balance
    └── active_avatar          # Current AI avatar selection

activities/                     # Social feed posts
├── {activityId}/
    ├── userId
    ├── type                   # workout, meal, eco_action, achievement
    ├── visibility             # supporters, community, public
    ├── content
    └── timestamp

friendships/                    # Supporter connections
├── {friendshipId}/
    ├── userId
    ├── friendId
    ├── status                 # pending, accepted
    └── createdAt

follows/                        # Bidirectional support system
├── {followId}/
    ├── followerId
    ├── followingId
    └── timestamp

conversations/                  # Chat conversations
├── {conversationId}/
    ├── participants[]
    ├── lastMessage
    ├── lastMessageTime
    └── unreadCount

messages/                       # Chat messages
├── {conversationId}/
    └── {messageId}/
        ├── senderId
        ├── text
        ├── timestamp
        └── read

challenges/                     # Community challenges
├── {challengeId}/
    ├── title
    ├── description
    ├── type                   # fitness, sustainability
    ├── participants[]
    ├── leaderboard
    ├── startDate
    └── endDate

tribes/                         # Community groups
├── {tribeId}/
    ├── name
    ├── description
    ├── category
    ├── members[]
    ├── moderators[]
    └── createdAt

tribe_posts/                    # Tribe-specific content
├── {postId}/
    ├── tribeId
    ├── userId
    ├── content
    └── timestamp

exercise_logs/                  # Workout history
├── {logId}/
    ├── userId
    ├── exercises[]
    ├── duration
    ├── caloriesBurned
    └── timestamp

avatar_store/                   # Available AI avatars
├── {avatarId}/
    ├── name
    ├── description
    ├── personality
    ├── price
    ├── membershipRequired
    └── imageUrl

user_avatars/                   # Owned avatars per user
├── {userId}/
    └── {avatarId}/
        ├── purchased
        └── customization
```

---

## 🎯 Core User Flows

### New User Onboarding

1. **Animated splash screen** (Lottie animation)
2. Sign up with Google/Facebook/Email/Apple
3. Audio preference selection
4. Ceremonial intro experience
5. Personal information setup
6. Fitness goals and preferences
7. Dietary restrictions configuration
8. Sustainability goals selection
9. Privacy settings configuration
10. Friend discovery and tribe joining

### Daily Engagement Loop

1. Launch app → Animated splash screen
2. Dashboard: Check supporter activities and challenges
3. Log meals with AI food recognition
4. Complete workouts with exercise tracking
5. Chat with Solar AI for personalized guidance
6. Engage with community through comments and likes
7. Track eco-friendly activities
8. Share achievements with supporters

### Sustainability Integration

1. Track eco-friendly activities (cycling, public transport)
2. View CO2 savings and sustainability score
3. Receive eco tips from AI assistant
4. Participate in sustainability challenges
5. Compare progress with community
6. Unlock sustainability achievements

### Social Interaction Flow

1. Discover users through search or suggestions
2. Send support requests
3. View enhanced supporter profiles with shared data
4. Engage via real-time chat
5. Join relevant tribes
6. Participate in community challenges
7. Share progress and celebrate achievements

---

## 🛠️ Development Setup

### Prerequisites

```bash
Flutter SDK 3.6.0 or higher
Dart SDK 3.0.0 or higher
Firebase CLI
Android Studio / Xcode (for platform builds)
Git
```

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/solarvita.git
cd solarvita

# Install dependencies
flutter pub get

# Generate app icons
dart run flutter_launcher_icons

# Configure Firebase
flutterfire configure

# Run app (debug mode)
flutter run

# Build for release
flutter build apk --release        # Android
flutter build ios --release        # iOS (requires Apple Developer account)
```

### Environment Variables

Create `.env` file in project root:

```env
GEMINI_API_KEY=your_gemini_api_key
NUTRITIONIX_APP_ID=your_nutritionix_app_id
NUTRITIONIX_APP_KEY=your_nutritionix_app_key
```

### App Icons Configuration

Icons are automatically generated using `flutter_launcher_icons`:

```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#161f25"
  adaptive_icon_foreground: "assets/images/logo.png"
```

Run `dart run flutter_launcher_icons` to generate all icon sizes.

### Splash Screen

- **Native splash**: Dark background (#161f25) with logo
- **Lottie animated splash**: Plays on app launch (works during phone calls)
- Location: `assets/videos/animation.json`

---

## 🌍 Internationalization

### Supported Languages (11 Total)

- 🇬🇧 **English (EN)** - Base language
- 🇪🇸 **Spanish (ES)**
- 🇵🇹 **Portuguese (PT)**
- 🇫🇷 **French (FR)**
- 🇮🇹 **Italian (IT)**
- 🇩🇪 **German (DE)**
- 🇨🇳 **Chinese (ZH)**
- 🇯🇵 **Japanese (JA)**
- 🇷🇺 **Russian (RU)**
- 🇮🇳 **Hindi (HI)**
- 🇰🇷 **Korean (KO)**

### Translation Structure

```
assets/i18n/
├── en/ (English - base language)
├── es/ (Spanish)
├── pt/ (Portuguese)
├── fr/ (French)
├── it/ (Italian)
├── de/ (German)
├── zh/ (Chinese)
├── ja/ (Japanese)
├── ru/ (Russian)
├── hi/ (Hindi)
└── ko/ (Korean)
```

Each language folder contains categorized JSON files:

- `onboarding.json` - Onboarding flow
- `dashboard.json` - Home screen
- `health.json` - Nutrition & fitness
- `profile.json` - User settings
- `social.json` - Community features
- `common.json` - Shared strings

### Firebase Translation Service

- Dynamic translations stored in Firestore
- Fallback to local JSON files
- Real-time translation updates
- Cultural adaptation for region-specific content

---

## 📈 Skills Demonstrated

This project showcases expertise in:

### Mobile Development

- **Cross-platform Flutter development** with complex UI/UX
- **Advanced state management** (Provider + Riverpod patterns)
- **Firebase full-stack integration** with 8+ services
- **Real-time data synchronization** for chat and social features
- **Offline-first architecture** with caching strategies
- **Platform-specific features** (iOS/Android native integration)

### API Integration

- **RESTful API consumption** with error handling
- **Multi-API orchestration** (Gemini, Nutritionix, Vision)
- **Rate limiting** and caching strategies
- **OAuth2 authentication** flows (Google, Facebook, Apple)
- **Webhook handling** with Firebase Cloud Functions
- **Payment processing** (Google Pay, Apple Pay, In-App Purchases)

### AI & Machine Learning

- **Large Language Model integration** (Google Gemini 1.5)
- **Computer Vision API usage** (food recognition)
- **Context-aware AI responses** using user profile data
- **Multi-modal AI applications** (text + image)
- **AI rate limiting** and cost optimization
- **Personalization algorithms**

### Software Engineering

- **Scalable architecture design** with clean separation of concerns
- **SOLID principles** and design patterns
- **Comprehensive error handling** and logging
- **Performance optimization** techniques
- **Security best practices** (encryption, secure storage)
- **Code documentation** and maintainability
- **Version control** with Git

### Backend & Database

- **NoSQL database design** (Firestore schema architecture)
- **Real-time database** implementation (Firebase Realtime DB)
- **Cloud Functions** for serverless backend logic
- **Database security rules** and access control
- **Data modeling** for complex relationships
- **Query optimization** and indexing

### User Experience

- **11-language internationalization** with cultural adaptation
- **Dynamic theming** (light/dark modes with Material Design 3)
- **Responsive design** across screen sizes
- **Privacy-first feature design** with granular controls
- **Accessibility** considerations and WCAG compliance
- **Smooth animations** and micro-interactions
- **Intuitive navigation** patterns

### DevOps & Tools

- **CI/CD pipelines** preparation
- **Environment configuration** management
- **Asset optimization** (images, animations)
- **Build configuration** for multiple platforms
- **Testing strategies** (unit, widget, integration)
- **Performance monitoring** preparation

---

## 🔄 Future Roadmap

### Planned Features (Q2-Q4 2025)

- ✅ **Wearable integration**: Apple Watch, Fitbit, Samsung Health
- ✅ **Video workouts**: Guided exercise sessions with instructors
- ✅ **Advanced analytics**: Detailed progress tracking dashboard
- ✅ **Enhanced tribe features**: Tribe challenges and leaderboards
- ✅ **Voice messaging**: Voice notes in chat conversations
- ✅ **Avatar AI improvements**: More sophisticated personality systems
- ✅ **Meal planning AI**: Advanced personalized nutrition recommendations
- ✅ **Carbon offset marketplace**: Real environmental impact actions
- ✅ **Group video calls**: Virtual workout sessions with supporters
- ✅ **Gamification**: Expanded achievement system with rewards
- ✅ **Social stories**: Instagram-style fitness stories (24h expiry)

### Technical Improvements

- ✅ **Complete offline support**: Expanded offline capabilities for all features
- ⚙️ **Advanced push notifications**: Intelligent workout and meal reminders (partially implemented)
- ✅ **Background sync**: Automatic data synchronization improvements
- ✅ **Performance monitoring**: Real-time app performance tracking with Firebase
- ✅ **Advanced caching**: Smarter data storage and retrieval
- ✅ **Message encryption**: End-to-end encryption for chat messages
- ⚙️ **Audio/video calling**: Real-time communication features (planned)
- ✅ **Automated testing**: Comprehensive test suite for all features
- ✅ **Analytics dashboard**: User engagement and retention metrics

---

## 🏆 Project Achievements

### Technical Milestones

- ✅ **650+ commits** with clean Git history
- ✅ **50,000+ lines** of production Dart code
- ✅ **11 languages** fully localized
- ✅ **8 Firebase services** integrated
- ✅ **4 major API integrations** (Gemini, Nutritionix, Vision, ExerciseDB)
- ✅ **100+ custom widgets** and components
- ✅ **Real-time chat system** with message encryption
- ✅ **AI avatar marketplace** with virtual economy
- ✅ **Bidirectional social system** with privacy controls
- ✅ **Comprehensive settings** with 50+ configuration options

### Features Implemented

- ✅ Multi-platform authentication (5 providers)
- ✅ AI-powered coaching with context awareness
- ✅ Food recognition and nutrition tracking
- ✅ Workout logging with 50+ exercises
- ✅ Carbon footprint tracking
- ✅ Real-time messaging system
- ✅ Community tribes and challenges
- ✅ Avatar store with coin economy
- ✅ Offline-first architecture
- ✅ Dynamic theming and internationalization

---

## 📄 License

This project is developed as a portfolio piece demonstrating modern mobile app development practices. All rights reserved.

---

## 🤝 Contributing

This is a personal portfolio project. However, feedback and suggestions are welcome via:

- GitHub Issues for bug reports
- Pull Requests for improvements (subject to review)
- Email for collaboration inquiries

---

## 📞 Contact & Links

**Rui Seca**
Full-Stack Mobile Developer | Flutter Specialist

- 📧 **Email**: ruiviegas.seca@gmail.com
- 💼 **LinkedIn**: [linkedin.com/in/rui-seca](https://linkedin.com/in/rui-seca/)
- 🌐 **Portfolio**: [portfolio-show-case.netlify.app](https://portfolio-show-case.netlify.app/)
- 💻 **GitHub**: [github.com/yourusername](https://github.com/RuiSeca)

---

## 🙏 Acknowledgments

### Technologies & Services

- **Flutter Team** - Amazing cross-platform framework
- **Firebase** - Comprehensive backend platform
- **Google AI** - Gemini API for intelligent coaching
- **Nutritionix** - Extensive nutrition database
- **LottieFiles** - Beautiful animations

### Inspiration

This app was built to demonstrate that technology can empower individuals to improve both personal health and environmental sustainability simultaneously.

---

**SolarVita** - Where personal wellness meets environmental responsibility.
Built with Flutter 💙 and a commitment to sustainability 🌱

---

## 📊 Quick Stats

```
Lines of Code:     50,000+
Widgets:           100+
Screens:           40+
Languages:         11
API Integrations:  4
Firebase Services: 8
Development Time:  6+ months
Commits:           650+
```

**Last Updated**: October 2025
**Version**: 1.0.0
**Status**: Active Development
