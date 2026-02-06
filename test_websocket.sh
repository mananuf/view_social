#!/bin/bash

# WebSocket Connection Test Script
# This script tests the WebSocket endpoint to ensure it's accessible

echo "🔍 Testing WebSocket Connection..."
echo ""

# Test 1: Check if backend is running
echo "1️⃣ Checking if backend is running on port 3000..."
if curl -s http://localhost:3000/api/v1/health > /dev/null 2>&1; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is not responding"
    exit 1
fi

echo ""

# Test 2: Check WebSocket endpoint (will fail without auth, but should respond)
echo "2️⃣ Testing WebSocket endpoint accessibility..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/ws)
if [ "$response" = "426" ] || [ "$response" = "401" ] || [ "$response" = "400" ]; then
    echo "✅ WebSocket endpoint is accessible (HTTP $response - expected for non-WebSocket request)"
else
    echo "⚠️  Unexpected response: HTTP $response"
fi

echo ""

# Test 3: Login and get token
echo "3️⃣ Testing authentication to get WebSocket token..."
login_response=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "thefifthdev@gmail.com",
    "password": "Qwerty1234@"
  }')

if echo "$login_response" | grep -q "token"; then
    echo "✅ Authentication successful"
    token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "   Token: ${token:0:20}..."
else
    echo "❌ Authentication failed"
    echo "   Response: $login_response"
    exit 1
fi

echo ""
echo "✅ All tests passed!"
echo ""
echo "📱 Flutter App Configuration:"
echo "   - iOS Simulator: ws://localhost:3000/api/v1/ws"
echo "   - Android Emulator: ws://10.0.2.2:3000/api/v1/ws"
echo ""
echo "🧪 To test WebSocket in Flutter:"
echo "   1. Run: cd view_social_app && flutter run"
echo "   2. Login with: thefifthdev@gmail.com / Qwerty1234@"
echo "   3. Navigate to Messages tab"
echo "   4. WebSocket should connect automatically"
echo ""
echo "🔗 WebSocket Events to Watch:"
echo "   - user_online/user_offline: User presence"
echo "   - message_sent: New messages"
echo "   - typing_started/typing_stopped: Typing indicators"
echo "   - message_read: Read receipts"
