# DiplomaKids - Modern Educational Savings Social Platform

<div align="center">
  <img src="assets/logo.png" alt="DiplomaKids Logo" width="200"/>
  
  [![React Native](https://img.shields.io/badge/React%20Native-0.72.3-blue)](https://reactnative.dev/)
  [![Expo](https://img.shields.io/badge/Expo-49.0.0-black)](https://expo.dev/)
  [![FastAPI](https://img.shields.io/badge/FastAPI-0.103.0-green)](https://fastapi.tiangolo.com/)
  [![Supabase](https://img.shields.io/badge/Supabase-Latest-orange)](https://supabase.com/)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
</div>

## 🎓 Overview

DiplomaKids is a revolutionary social-first 529 savings platform that transforms college savings into an engaging, community-driven experience. Families can share educational milestones, receive contributions from their network, and gamify the journey to college savings success.

### 🌟 Key Features

- **📱 Social Feed**: Share and celebrate educational milestones with photos, videos, and achievements
- **💰 Smart Contributions**: One-time and recurring gifts with QR codes and gift registries
- **🎮 Gamification**: Achievement badges, savings thermometers, and leaderboards
- **📊 Analytics Dashboard**: Portfolio tracking, tax documents, and college cost calculators
- **🎯 Goal Setting**: Visual progress tracking and milestone celebrations
- **👨‍👩‍👧‍👦 Family Profiles**: Multi-child support with individual savings goals
- **🔒 Security First**: End-to-end encryption, COPPA compliant, SOC 2 ready

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm/yarn
- Docker and Docker Compose
- Expo CLI (`npm install -g expo-cli`)
- iOS Simulator (Mac) or Android Emulator
- Stripe Account (for payments)
- Supabase Account (or local setup)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/diplomakids.git
cd diplomakids
```

2. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start the backend services**
```bash
docker-compose up -d
```

4. **Initialize the database**
```bash
docker exec -i diplomakids-db psql -U postgres diplomakids < diplomakids-supabase-schema.sql
```

5. **Install mobile app dependencies**
```bash
cd diplomakids-app
npm install
```

6. **Start the Expo development server**
```bash
npx expo start
```

7. **Run on your device**
- Press `i` for iOS simulator
- Press `a` for Android emulator
- Scan QR code with Expo Go app on physical device

## 🏗️ Architecture

### Technology Stack

#### Frontend (Mobile App)
- **Framework**: React Native with Expo
- **State Management**: Redux Toolkit + React Query
- **Navigation**: React Navigation 6
- **UI Components**: React Native Paper + Custom Components
- **Animations**: React Native Reanimated 3
- **Charts**: React Native Chart Kit
- **Payments**: Stripe React Native SDK

#### Backend
- **API**: FastAPI (Python)
- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth with Social Providers
- **File Storage**: Supabase Storage / MinIO
- **Cache**: Redis
- **Queue**: Celery with Redis
- **Payments**: Stripe Connect

#### Infrastructure
- **Container**: Docker & Docker Compose
- **API Gateway**: Kong
- **Reverse Proxy**: Nginx
- **CI/CD**: GitHub Actions
- **Monitoring**: Sentry + DataDog
- **Analytics**: Mixpanel + Amplitude

### Project Structure

```
diplomakids/
├── diplomakids-app/           # React Native mobile application
│   ├── src/
│   │   ├── screens/          # Screen components
│   │   ├── components/       # Reusable components
│   │   ├── contexts/         # React contexts
│   │   ├── services/         # API services
│   │   ├── store/           # Redux store
│   │   └── utils/           # Utilities
│   ├── assets/              # Images, fonts, etc.
│   ├── app.json            # Expo configuration
│   └── package.json        # Dependencies
│
├── backend/                 # FastAPI backend
│   ├── main.py            # Main application
│   ├── models/            # Database models
│   ├── routes/            # API routes
│   ├── services/          # Business logic
│   └── requirements.txt   # Python dependencies
│
├── database/               # Database schemas
│   └── schema.sql         # Supabase schema
│
├── docker-compose.yml     # Docker services
├── nginx.conf            # Nginx configuration
└── README.md            # Documentation
```

## 📱 Mobile App Features

### Screens & Navigation

1. **Onboarding Flow**
   - Welcome screens with platform benefits
   - Social login (Facebook, Google, Apple)
   - Family profile setup
   - Child profile creation

2. **Home Feed**
   - Milestone posts with media
   - Like, comment, share interactions
   - Quick contribution buttons
   - Progress visualizations

3. **Contribution System**
   - Amount selection with presets
   - Payment method selection
   - Recurring contribution setup
   - Thank you message recording

4. **Goals Dashboard**
   - Savings thermometer
   - Goal progress tracking
   - Projected completion dates
   - Achievement badges display

5. **Family Profile**
   - Multi-child management
   - 529 plan linking
   - Privacy settings
   - Social connections

## 🔧 API Documentation

### Authentication Endpoints

```http
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
```

### Core Endpoints

```http
# Families
GET    /api/v1/families/profile
PUT    /api/v1/families/profile
POST   /api/v1/families/connect

# Children
GET    /api/v1/children
POST   /api/v1/children
GET    /api/v1/children/{child_id}
PUT    /api/v1/children/{child_id}

# Contributions
POST   /api/v1/contributions
GET    /api/v1/contributions/child/{child_id}
POST   /api/v1/contributions/thank-you/{contribution_id}

# Feed & Milestones
GET    /api/v1/feed
POST   /api/v1/milestones
GET    /api/v1/milestones/{milestone_id}
POST   /api/v1/milestones/{milestone_id}/like
POST   /api/v1/milestones/{milestone_id}/comment

# Goals
POST   /api/v1/goals
GET    /api/v1/goals/child/{child_id}
PUT    /api/v1/goals/{goal_id}

# Analytics
GET    /api/v1/analytics/portfolio/{child_id}
GET    /api/v1/analytics/leaderboard
GET    /api/v1/analytics/tax-summary
```

## 🔐 Security & Compliance

### Data Protection
- End-to-end encryption for sensitive data
- PCI DSS compliance via Stripe
- COPPA compliant for child data
- GDPR ready with data export/deletion

### Authentication
- Multi-factor authentication support
- Biometric authentication on mobile
- OAuth 2.0 with social providers
- JWT with refresh token rotation

### Privacy Controls
- Granular privacy settings per child
- Content moderation for posts
- Parental controls and approvals
- Data retention policies

## 🚢 Deployment

### Mobile App Deployment

#### iOS (App Store)
```bash
# Build for iOS
eas build --platform ios

# Submit to App Store
eas submit --platform ios
```

#### Android (Google Play)
```bash
# Build for Android
eas build --platform android

# Submit to Google Play
eas submit --platform android
```

### Backend Deployment

#### Using Docker
```bash
# Build and deploy
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker exec diplomakids-backend python manage.py migrate
```

#### Using Kubernetes
```bash
# Apply configurations
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n diplomakids
```

## 📊 Analytics & Monitoring

### Key Metrics
- User acquisition and retention
- Contribution volume and frequency
- Goal completion rates
- Social engagement metrics
- Feature adoption rates

### Monitoring Stack
- **APM**: DataDog / New Relic
- **Error Tracking**: Sentry
- **Analytics**: Mixpanel + Amplitude
- **Logging**: ELK Stack
- **Uptime**: Pingdom / UptimeRobot

## 🧪 Testing

### Mobile App Testing
```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests with Detox
npm run test:e2e
```

### Backend Testing
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_contributions.py
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- **JavaScript/React**: ESLint + Prettier
- **Python**: Black + isort + flake8
- **Commits**: Conventional Commits

## 📝 Environment Variables

Create a `.env` file with the following variables:

```env
# Supabase
SUPABASE_URL=http://localhost:8000
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_key

# Database
DATABASE_URL=postgres://postgres:password@localhost:5432/diplomakids
POSTGRES_PASSWORD=diplomakids123

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# Email (Resend/SendGrid)
RESEND_API_KEY=re_...
SMTP_HOST=smtp.sendgrid.net
SMTP_USER=apikey
SMTP_PASS=SG...

# Push Notifications
EXPO_PUSH_TOKEN=ExponentPushToken[...]

# OAuth Providers
GOOGLE_CLIENT_ID=...
FACEBOOK_APP_ID=...
APPLE_TEAM_ID=...

# OpenAI (for AI features)
OPENAI_API_KEY=sk-...

# JWT
JWT_SECRET=your-secret-key-at-least-32-chars

# Redis
REDIS_URL=redis://localhost:6379

# MinIO (Object Storage)
MINIO_ROOT_USER=diplomakids
MINIO_ROOT_PASSWORD=diplomakids123
```

## 🛠️ Troubleshooting

### Common Issues

#### Mobile App Won't Start
```bash
# Clear cache and reinstall
npx expo start -c
rm -rf node_modules
npm install
```

#### Database Connection Issues
```bash
# Check database status
docker-compose logs supabase-db

# Restart database
docker-compose restart supabase-db
```

#### Build Failures
```bash
# Clear build cache
eas build:clear-cache

# Update Expo SDK
expo upgrade
```

## 📚 Resources

- [React Native Documentation](https://reactnative.dev/docs/getting-started)
- [Expo Documentation](https://docs.expo.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Stripe Documentation](https://stripe.com/docs)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to all contributors and early adopters
- Special thanks to the open source community
- Inspired by the need to make education savings accessible and social

## 📧 Contact

- **Email**: support@diplomakids.com
- **Twitter**: [@diplomakids](https://twitter.com/diplomakids)
- **Discord**: [Join our community](https://discord.gg/diplomakids)

---

<div align="center">
  Made with ❤️ for families saving for education
  
  **Star ⭐ this repo if you find it helpful!**
</div>
# DiplomaKids-Modernized
