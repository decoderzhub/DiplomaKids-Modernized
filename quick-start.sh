#!/bin/bash

# DiplomaKids Quick Start Script
# This script sets up the DiplomaKids platform quickly for development

echo "🎓 DiplomaKids Quick Setup Starting..."

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm is required but not installed. Aborting." >&2; exit 1; }

# Create environment file if not exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOF
# Supabase Configuration
SUPABASE_URL=http://localhost:8000
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# Database
DATABASE_URL=postgres://postgres:diplomakids123@localhost:5432/diplomakids
POSTGRES_PASSWORD=diplomakids123

# Stripe (Add your test keys)
STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET_HERE
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE

# Email Service (Add your keys)
RESEND_API_KEY=re_YOUR_KEY_HERE

# JWT
JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long

# Redis
REDIS_URL=redis://localhost:6379

# MinIO
MINIO_ROOT_USER=diplomakids
MINIO_ROOT_PASSWORD=diplomakids123

# OpenAI (Optional)
OPENAI_API_KEY=sk_YOUR_KEY_HERE
EOF
    echo "✅ .env file created (Please add your API keys)"
fi

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Install backend dependencies
echo "🐍 Setting up Python backend..."
if [ ! -f requirements.txt ]; then
    cat > requirements.txt << EOF
fastapi==0.103.0
uvicorn[standard]==0.23.2
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-dotenv==1.0.0
stripe==6.5.0
supabase==1.2.0
resend==0.7.0
redis==5.0.0
celery==5.3.1
httpx==0.25.0
pydantic==2.3.0
pydantic[email]==2.3.0
qrcode==7.4.2
Pillow==10.0.0
openai==0.28.0
python-dateutil==2.8.2
EOF
fi

# Install Python dependencies in Docker
docker exec diplomakids-backend pip install -r /app/requirements.txt

# Setup mobile app
echo "📱 Setting up React Native app..."
cd diplomakids-app

# Install Expo CLI globally if not installed
if ! command -v expo &> /dev/null; then
    echo "📦 Installing Expo CLI..."
    npm install -g expo-cli
fi

# Install dependencies
echo "📦 Installing mobile app dependencies..."
npm install

# Create app.json if not exists
if [ ! -f app.json ]; then
    cat > app.json << EOF
{
  "expo": {
    "name": "DiplomaKids",
    "slug": "diplomakids",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "light",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#4A90E2"
    },
    "assetBundlePatterns": [
      "**/*"
    ],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.diplomakids.app",
      "infoPlist": {
        "NSCameraUsageDescription": "This app uses the camera to capture milestone photos and videos.",
        "NSPhotoLibraryUsageDescription": "This app needs access to photo library to upload milestone photos."
      }
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#4A90E2"
      },
      "package": "com.diplomakids.app",
      "permissions": [
        "CAMERA",
        "READ_EXTERNAL_STORAGE",
        "WRITE_EXTERNAL_STORAGE"
      ]
    },
    "web": {
      "favicon": "./assets/favicon.png"
    },
    "plugins": [
      "@stripe/stripe-react-native",
      "expo-camera",
      "expo-notifications"
    ],
    "extra": {
      "eas": {
        "projectId": "YOUR_PROJECT_ID"
      }
    }
  }
}
EOF
fi

# Create placeholder assets if not exists
mkdir -p assets
if [ ! -f assets/icon.png ]; then
    echo "🎨 Creating placeholder assets..."
    # Create a simple colored square as placeholder
    convert -size 1024x1024 xc:'#4A90E2' assets/icon.png 2>/dev/null || echo "⚠️  ImageMagick not found. Please add icon.png manually."
    convert -size 1024x1024 xc:'#4A90E2' assets/splash.png 2>/dev/null || echo "⚠️  ImageMagick not found. Please add splash.png manually."
    convert -size 512x512 xc:'#4A90E2' assets/adaptive-icon.png 2>/dev/null || echo "⚠️  ImageMagick not found. Please add adaptive-icon.png manually."
    convert -size 48x48 xc:'#4A90E2' assets/favicon.png 2>/dev/null || echo "⚠️  ImageMagick not found. Please add favicon.png manually."
fi

# Create fonts directory
mkdir -p assets/fonts
echo "📁 Fonts directory created at assets/fonts"
echo "⚠️  Please add Poppins font files manually to assets/fonts/"

cd ..

echo "
✅ ========================================
✅ DiplomaKids Setup Complete!
✅ ========================================

📋 Next Steps:

1. Add your API keys to the .env file:
   - Stripe keys (get from https://dashboard.stripe.com/test/apikeys)
   - Email service keys (Resend or SendGrid)
   - OpenAI key (optional)

2. Access the services:
   🌐 Backend API: http://localhost:8080
   🗄️ Supabase Studio: http://localhost:54323
   📦 MinIO Console: http://localhost:9001
   🔄 Realtime: ws://localhost:4000

3. Start the mobile app:
   cd diplomakids-app
   npx expo start

   Then:
   - Press 'i' for iOS simulator
   - Press 'a' for Android emulator
   - Scan QR with Expo Go app on your phone

4. Default credentials:
   - MinIO: diplomakids / diplomakids123
   - Database: postgres / diplomakids123

⚠️  Important:
   - Add Poppins font files to diplomakids-app/assets/fonts/
   - Replace placeholder images in diplomakids-app/assets/
   - Update API keys in .env before production

📚 Documentation: See README.md for detailed information

🆘 Troubleshooting:
   - If services fail to start: docker-compose logs [service-name]
   - If mobile app fails: cd diplomakids-app && npx expo doctor
   - Database issues: docker-compose restart supabase-db

Happy building! 🚀
"
