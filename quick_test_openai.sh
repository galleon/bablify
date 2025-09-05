#!/bin/bash

# Quick OpenAI Test Script
# Test basic text chat functionality without voice/audio components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check .env file
if [[ ! -f ".env" ]]; then
    print_error ".env file not found"
    exit 1
fi

source .env

if [[ -z "$OPENAI_API_KEY" || "$OPENAI_API_KEY" == "your_openai_api_key_here" ]]; then
    print_error "Please set your OpenAI API key in .env file"
    exit 1
fi

print_status "Creating minimal text-only config..."

# Create minimal config with API key from environment
cat > temp_text_only_config.yaml << EOF
default:
  logger:
    log_level: "INFO"
  service:
    host: "0.0.0.0"
    port: 8282
    cert_file: "ssl_certs/localhost.crt"
    cert_key: "ssl_certs/localhost.key"
  chat_engine:
    model_root: "models"
    concurrent_limit: 1
    handler_search_path:
      - "src/handlers"
    handler_configs:
      RtcClient:
        module: client/rtc_client/client_handler_rtc
      LLMOpenAICompatible:
        enabled: True
        module: llm/openai_compatible/llm_handler_openai_compatible
        model_name: "gpt-3.5-turbo"
        enable_video_input: False
        history_length: 20
        system_prompt: "You are an AI assistant. Respond with 'Hello! I am working correctly.' to test messages."
        api_url: "https://api.openai.com/v1"
        api_key: "$OPENAI_API_KEY"
EOF

print_status "Stopping existing container..."
docker rm -f open-avatar-chat-text-test 2>/dev/null || true

print_status "Starting minimal text-only test container..."
CONTAINER_ID=$(docker run -d \
    --name open-avatar-chat-text-test \
    --platform linux/arm64 \
    -p 8284:8282 \
    -v "$(pwd)/temp_text_only_config.yaml:/root/open-avatar-chat/config/temp_text_only_config.yaml" \
    -e OPENAI_API_KEY="$OPENAI_API_KEY" \
    --memory=8g \
    --cpus=4.0 \
    --entrypoint="" \
    open-avatar-chat:mac-m3 \
    /bin/bash -c "cd /root/open-avatar-chat && uv run src/demo.py --config config/temp_text_only_config.yaml")

if [[ $? -eq 0 ]]; then
    print_success "Container started: ${CONTAINER_ID:0:12}"
    print_status "Text-only test interface: https://localhost:8284"
    print_status ""
    print_status "Monitoring startup logs..."

    # Monitor logs for 30 seconds
    for i in {1..15}; do
        LOGS=$(docker logs --tail 5 open-avatar-chat-text-test 2>&1)
        echo "$LOGS"

        if echo "$LOGS" | grep -q "Uvicorn running"; then
            print_success "Server is running!"
            break
        fi

        if echo "$LOGS" | grep -qE "(Error|Exception|Failed)"; then
            print_error "Error detected in logs"
            break
        fi

        sleep 2
        printf "."
    done

    echo ""
    print_status "=== Test Results ==="
    print_status "1. Open: https://localhost:8284"
    print_status "2. Try typing: 'test message'"
    print_status "3. Expected response: 'Hello! I am working correctly.'"
    print_status "4. Monitor logs: docker logs -f open-avatar-chat-text-test"
    print_status "5. Stop test: docker stop open-avatar-chat-text-test"

    print_status "This test removes voice/audio components to isolate text chat."

else
    print_error "Failed to start test container"
    exit 1
fi
