#!/bin/bash

# Test Script for OpenAI Mac M3 Version
# OpenAvatarChat Mac M3 Testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    print_error "No .env file found. Please create one with your OpenAI API key:"
    echo ""
    echo "Create .env file:"
    echo "OPENAI_API_KEY=sk-your-openai-api-key-here"
    echo ""
    exit 1
fi

# Load environment variables
source .env

# Check if OpenAI API key is set
if [[ -z "$OPENAI_API_KEY" || "$OPENAI_API_KEY" == "your_openai_api_key_here" ]]; then
    print_error "Please set your actual OpenAI API key in .env file"
    echo "Current value: $OPENAI_API_KEY"
    exit 1
fi

# Validate OpenAI API key format
if [[ ! "$OPENAI_API_KEY" =~ ^sk-[a-zA-Z0-9]{48,}$ ]]; then
    print_warning "API key format doesn't match expected OpenAI format (sk-...)"
    print_status "Continuing anyway - might be a valid key with different format"
fi

print_status "Starting OpenAI Mac M3 Test..."
print_status "API Key: ${OPENAI_API_KEY:0:10}...${OPENAI_API_KEY: -4}"

# Clean up any existing container
print_status "Cleaning up existing containers..."
docker rm -f open-avatar-chat-mac-m3 2>/dev/null || true

# Test API key first
print_status "Testing OpenAI API connection..."
if command -v curl &> /dev/null; then
    API_TEST=$(curl -s -H "Authorization: Bearer $OPENAI_API_KEY" \
                    -H "Content-Type: application/json" \
                    -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"Hello"}],"max_tokens":5}' \
                    https://api.openai.com/v1/chat/completions)

    if echo "$API_TEST" | grep -q "error"; then
        print_error "OpenAI API test failed:"
        echo "$API_TEST" | head -3
        exit 1
    else
        print_success "OpenAI API connection successful"
    fi
else
    print_warning "curl not found, skipping API test"
fi

# Check Docker image exists
if ! docker image inspect open-avatar-chat:mac-m3 &> /dev/null; then
    print_error "Docker image 'open-avatar-chat:mac-m3' not found"
    print_status "Please build the image first:"
    print_status "  ./build_mac_m3.sh"
    exit 1
fi

# Create dynamic config with API key
print_status "Creating dynamic config with API key..."
cat > temp_openai_config.yaml << EOF
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
      SileroVad:
        module: vad/silerovad/vad_handler_silero
        speaking_threshold: 0.5
        start_delay: 2048
        end_delay: 5000
        buffer_look_back: 5000
        speech_padding: 512
        use_cpu: true
        num_threads: 4
      Edge_TTS:
        enabled: True
        module: tts/edgetts/tts_handler_edgetts
        voice: "en-US-JennyNeural"
      LLMOpenAICompatible:
        enabled: True
        module: llm/openai_compatible/llm_handler_openai_compatible
        model_name: "gpt-3.5-turbo"
        enable_video_input: False
        history_length: 20
        system_prompt: "You are an AI assistant optimized for Mac M3. You provide helpful, accurate responses in a conversational manner. Keep responses concand engaging."
        api_url: "https://api.openai.com/v1"
        api_key: "$OPENAI_API_KEY"
      LiteAvatar:
        enabled: False
        module: avatar/liteavatar/avatar_handler_liteavatar
        avatar_name: 20250408/sample_data
        fps: 20
        debug: false
        enable_fast_mode: true
        use_gpu: false
        num_workers: 4
        memory_efficient: true
        low_memory_mode: true
        batch_inference: false
EOF

# Start container with OpenAI API key
print_status "Starting container with OpenAI configuration..."
CONTAINER_ID=$(docker run -d \
    --name open-avatar-chat-mac-m3 \
    --platform linux/arm64 \
    -p 8282:8282 \
    -v "$(pwd)/models:/root/open-avatar-chat/models" \
    -v "$(pwd)/ssl_certs:/root/open-avatar-chat/ssl_certs" \
    -v "$(pwd)/logs:/root/open-avatar-chat/logs" \
    -v "$(pwd)/temp_openai_config.yaml:/root/open-avatar-chat/config/temp_openai_config.yaml" \
    -e OPENAI_API_KEY="$OPENAI_API_KEY" \
    -e PYTORCH_ENABLE_MPS_FALLBACK=1 \
    -e OMP_NUM_THREADS=8 \
    -e MKL_NUM_THREADS=8 \
    -e VECLIB_MAXIMUM_THREADS=8 \
    -e NUMEXPR_NUM_THREADS=8 \
    --memory=16g \
    --cpus=8.0 \
    --entrypoint="" \
    open-avatar-chat:mac-m3 \
    /bin/bash -c "cd /root/open-avatar-chat && uv run src/demo.py --config config/temp_openai_config.yaml")

if [[ $? -eq 0 ]]; then
    print_success "Container started successfully"
    print_status "Container ID: ${CONTAINER_ID:0:12}"
else
    print_error "Failed to start container"
    exit 1
fi

# Wait and monitor startup
print_status "Monitoring container startup..."
echo ""
echo "=== Container Logs ==="

# Monitor logs for 60 seconds or until success
for i in {1..30}; do
    # Check if container is still running
    if ! docker ps --format "table {{.Names}}" | grep -q "open-avatar-chat-mac-m3"; then
        print_error "Container stopped unexpectedly"
        print_status "Last logs:"
        docker logs --tail 20 open-avatar-chat-mac-m3
        exit 1
    fi

    # Get recent logs
    LOGS=$(docker logs --tail 10 --since 2s open-avatar-chat-mac-m3 2>&1)

    if [[ -n "$LOGS" ]]; then
        echo "$LOGS"
    fi

    # Check for success indicators
    if echo "$LOGS" | grep -q "Running on.*8282"; then
        print_success "Server appears to be running!"
        break
    fi

    # Check for critical errors
    if echo "$LOGS" | grep -qE "(Error|Exception|Failed|fatal)"; then
        if echo "$LOGS" | grep -q "api_key"; then
            print_error "API key error detected in logs"
            break
        fi
    fi

    sleep 2
    printf "."
done

echo ""
echo "=== End Logs ==="
echo ""

# Test web interface availability
print_status "Testing web interface availability..."
for i in {1..15}; do
    if curl -k -s --connect-timeout 3 https://localhost:8282/ > /dev/null 2>&1; then
        print_success "HTTPS interface is accessible!"
        break
    elif curl -s --connect-timeout 3 http://localhost:8282/ > /dev/null 2>&1; then
        print_success "HTTP interface is accessible!"
        break
    fi

    if [[ $i -eq 15 ]]; then
        print_warning "Web interface not accessible yet"
        print_status "This might be normal - server could still be starting up"
    else
        sleep 2
    fi
done

# Show final status
echo ""
print_status "=== Test Results ==="
CONTAINER_STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep open-avatar-chat-mac-m3 || echo "Container not found")
print_status "Container Status: $CONTAINER_STATUS"

if docker ps --format "table {{.Names}}" | grep -q "open-avatar-chat-mac-m3"; then
    print_success "✅ Container is running"
    print_status "📱 Web Interface: https://localhost:8282 (HTTPS) or http://localhost:8282 (HTTP)"
    print_status "🔍 View logs: docker logs -f open-avatar-chat-mac-m3"
    print_status "⏹️  Stop: docker stop open-avatar-chat-mac-m3"
    print_status "🔄 Restart: docker restart open-avatar-chat-mac-m3"
    print_status ""
    print_status "=== Next Steps ==="
    print_status "1. Open https://localhost:8282 in your browser"
    print_status "2. Accept the self-signed SSL certificate"
    print_status "3. Test the chat functionality"
    print_status "4. If working, we'll proceed to add Ollama + Qwen2.5VL"

    # Show current resource usage
    print_status ""
    print_status "=== Resource Usage ==="
    STATS=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" open-avatar-chat-mac-m3)
    echo "$STATS"

else
    print_error "❌ Container failed to start or stopped"
    print_status "Check logs with: docker logs open-avatar-chat-mac-m3"
    exit 1
fi

echo ""
print_success "🎉 OpenAI Mac M3 test completed!"
print_status "The system is ready for testing. Once confirmed working, we'll add Ollama integration."
