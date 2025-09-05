#!/bin/bash

# Fix Timeout Script for OpenAvatarChat
# This script patches the frame processing timeout from 60s to 3600s

set -e

echo "🔧 Applying timeout fix for WebRTC frame processing..."

# Path to the utils.py file
UTILS_FILE="/root/open-avatar-chat/src/third_party/gradio_webrtc_videochat/backend/fastrtc/utils.py"

if [ -f "$UTILS_FILE" ]; then
    echo "📁 Found utils.py file"

    # Apply the timeout fix
    sed -i 's/timeout=60/timeout=3600/g' "$UTILS_FILE"
    sed -i 's/60 seconds/3600 seconds/g' "$UTILS_FILE"

    # Verify the fix was applied
    if grep -q "timeout=3600" "$UTILS_FILE"; then
        echo "✅ Timeout fix applied successfully (60s → 3600s)"
    else
        echo "❌ Failed to apply timeout fix"
        exit 1
    fi

    if grep -q "3600 seconds" "$UTILS_FILE"; then
        echo "✅ Timeout message updated successfully"
    else
        echo "❌ Failed to update timeout message"
        exit 1
    fi

else
    echo "❌ Utils file not found at $UTILS_FILE"
    exit 1
fi

echo "🎉 Timeout fix completed - WebRTC sessions can now run for 1 hour"
