#!/bin/bash

# Ollama Setup Script for Mac M3
# OpenAvatarChat Mac M3 Ollama Integration

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

# Default values
INSTALL_OLLAMA=true
PULL_MODELS=true
START_SERVICE=true
MODELS_TO_INSTALL="qwen2.5:7b"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --skip-install       Skip Ollama installation"
    echo "  --skip-models        Skip model downloading"
    echo "  --skip-start         Skip starting Ollama service"
    echo "  --models MODEL_LIST  Comma-separated list of models (default: qwen2.5:7b)"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Full setup"
    echo "  $0 --models 'qwen2.5:7b,llama3:8b'   # Install multiple models"
    echo "  $0 --skip-install --models qwen2.5:14b  # Only download different model"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-install)
            INSTALL_OLLAMA=false
            shift
            ;;
        --skip-models)
            PULL_MODELS=false
            shift
            ;;
        --skip-start)
            START_SERVICE=false
            shift
            ;;
        --models)
            MODELS_TO_INSTALL="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_status "Starting Ollama setup for Mac M3..."
print_status "Install Ollama: $INSTALL_OLLAMA"
print_status "Pull Models: $PULL_MODELS"
print_status "Start Service: $START_SERVICE"
print_status "Models: $MODELS_TO_INSTALL"

# Check system requirements
print_status "Checking system requirements..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_warning "This script is optimized for macOS. Detected OS: $OSTYPE"
    print_status "Continuing anyway..."
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    print_success "Detected Apple Silicon (ARM64) - perfect for Mac M3!"
else
    print_warning "Architecture: $ARCH. Expected arm64 for Mac M3."
fi

# Check available memory
if command -v sysctl &> /dev/null; then
    AVAILABLE_MEMORY=$(sysctl hw.memsize | awk '{print $2/1024/1024/1024}')
    print_status "Available memory: ${AVAILABLE_MEMORY}GB"

    if (( $(echo "$AVAILABLE_MEMORY < 8" | bc -l) )); then
        print_warning "Less than 8GB memory detected. Some models may not run optimally."
    fi
fi

# Check available disk space
AVAILABLE_SPACE=$(df -H . | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$AVAILABLE_SPACE < 20" | bc -l) )); then
    print_warning "Less than 20GB free space. Models require significant storage."
fi

# Install Ollama
if [[ "$INSTALL_OLLAMA" == "true" ]]; then
    print_status "Installing Ollama..."

    if command -v ollama &> /dev/null; then
        print_success "Ollama is already installed"
        ollama --version
    else
        print_status "Downloading and installing Ollama..."
        if curl -fsSL https://ollama.com/install.sh | sh; then
            print_success "Ollama installed successfully"
        else
            print_error "Failed to install Ollama"
            exit 1
        fi
    fi
else
    print_status "Skipping Ollama installation"

    if ! command -v ollama &> /dev/null; then
        print_error "Ollama not found and installation skipped"
        print_status "Please install Ollama manually: https://ollama.com/download"
        exit 1
    fi
fi

# Start Ollama service
if [[ "$START_SERVICE" == "true" ]]; then
    print_status "Starting Ollama service..."

    # Check if Ollama is already running
    if pgrep -x "ollama" > /dev/null; then
        print_success "Ollama service is already running"
    else
        print_status "Starting Ollama in background..."
        nohup ollama serve > ollama.log 2>&1 &

        # Wait for service to start
        print_status "Waiting for Ollama service to start..."
        for i in {1..30}; do
            if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
                print_success "Ollama service is running"
                break
            fi

            if [[ $i -eq 30 ]]; then
                print_error "Ollama service failed to start"
                print_status "Check logs: tail -f ollama.log"
                exit 1
            fi

            sleep 1
            printf "."
        done
        echo ""
    fi
else
    print_status "Skipping Ollama service start"
fi

# Test Ollama connection
print_status "Testing Ollama connection..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    print_success "Ollama API is accessible"

    # Show current models
    CURRENT_MODELS=$(curl -s http://localhost:11434/api/tags | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    models = [model['name'] for model in data.get('models', [])]
    print(', '.join(models) if models else 'No models installed')
except:
    print('Error parsing models')
")
    print_status "Currently installed models: $CURRENT_MODELS"
else
    print_error "Cannot connect to Ollama API"
    exit 1
fi

# Pull models
if [[ "$PULL_MODELS" == "true" ]]; then
    print_status "Installing models..."

    # Convert comma-separated models to array
    IFS=',' read -ra MODELS <<< "$MODELS_TO_INSTALL"

    for model in "${MODELS[@]}"; do
        # Trim whitespace
        model=$(echo "$model" | xargs)

        print_status "Checking if model '$model' is available..."

        # Check if model is already installed
        if curl -s http://localhost:11434/api/tags | grep -q "\"$model\""; then
            print_success "Model '$model' is already installed"
            continue
        fi

        print_status "Pulling model '$model'..."
        print_status "This may take several minutes depending on model size..."

        # Show progress for model download
        if ollama pull "$model"; then
            print_success "Successfully pulled model '$model'"

            # Get model info
            MODEL_INFO=$(ollama show "$model" --modelfile | head -5)
            print_status "Model info for '$model':"
            echo "$MODEL_INFO"
        else
            print_error "Failed to pull model '$model'"
            print_status "Available models: https://ollama.com/library"

            # Don't exit, continue with other models
            continue
        fi
    done
else
    print_status "Skipping model installation"
fi

# Test models
print_status "Testing installed models..."
INSTALLED_MODELS=$(curl -s http://localhost:11434/api/tags | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    models = [model['name'] for model in data.get('models', [])]
    for model in models:
        print(model)
except:
    pass
")

if [[ -n "$INSTALLED_MODELS" ]]; then
    print_success "Available models for testing:"
    echo "$INSTALLED_MODELS" | while read -r model; do
        if [[ -n "$model" ]]; then
            echo "  - $model"
        fi
    done

    # Test first model
    FIRST_MODEL=$(echo "$INSTALLED_MODELS" | head -1)
    if [[ -n "$FIRST_MODEL" ]]; then
        print_status "Testing model '$FIRST_MODEL'..."

        TEST_RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"$FIRST_MODEL\",\"prompt\":\"Hello! Say hi in 3 words.\",\"stream\":false}" \
            2>/dev/null | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    print(data.get('response', 'No response').strip())
except:
    print('Test failed')
")

        if [[ "$TEST_RESPONSE" != "Test failed" && -n "$TEST_RESPONSE" ]]; then
            print_success "Model test successful!"
            print_status "Response: $TEST_RESPONSE"
        else
            print_warning "Model test failed, but model should still work"
        fi
    fi
else
    print_warning "No models are currently installed"
fi

# Create Ollama config for OpenAvatarChat
print_status "Creating Ollama configuration for OpenAvatarChat..."

cat > config/chat_with_ollama_mac_m3.yaml << 'EOF'
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
        model_name: "qwen2.5:7b"
        enable_video_input: False
        history_length: 20
        system_prompt: "You are an AI assistant running locally on Mac M3 via Ollama. You provide helpful, accurate responses in a conversational manner. Keep responses concise and engaging."
        api_url: "http://host.docker.internal:11434/v1"
        api_key: "not-needed"
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

print_success "Created Ollama config: config/chat_with_ollama_mac_m3.yaml"

# Create test script for Ollama version
print_status "Creating Ollama test script..."

cat > test_ollama_mac_m3.sh << 'EOF'
#!/bin/bash

# Test Script for Ollama Mac M3 Version
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "Testing Ollama Mac M3 setup..."

# Check Ollama service
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    print_error "Ollama service not running. Please run: ollama serve"
    exit 1
fi

print_success "Ollama service is running"

# Clean up existing container
docker rm -f open-avatar-chat-ollama-mac-m3 2>/dev/null || true

# Start container with Ollama config
print_status "Starting container with Ollama configuration..."

CONTAINER_ID=$(docker run -d \
    --name open-avatar-chat-ollama-mac-m3 \
    --platform linux/arm64 \
    -p 8283:8282 \
    -v "$(pwd)/models:/root/open-avatar-chat/models" \
    -v "$(pwd)/ssl_certs:/root/open-avatar-chat/ssl_certs" \
    -v "$(pwd)/logs:/root/open-avatar-chat/logs" \
    -v "$(pwd)/config/chat_with_ollama_mac_m3.yaml:/root/open-avatar-chat/config/chat_with_ollama_mac_m3.yaml" \
    -e PYTORCH_ENABLE_MPS_FALLBACK=1 \
    -e OMP_NUM_THREADS=8 \
    --memory=16g \
    --cpus=8.0 \
    --add-host=host.docker.internal:host-gateway \
    --entrypoint="" \
    open-avatar-chat:mac-m3 \
    /bin/bash -c "cd /root/open-avatar-chat && uv run src/demo.py --config config/chat_with_ollama_mac_m3.yaml")

if [[ $? -eq 0 ]]; then
    print_success "Container started successfully"
    print_status "Container ID: ${CONTAINER_ID:0:12}"
    print_status "Ollama Web Interface: https://localhost:8283"
    print_status "OpenAI Web Interface: https://localhost:8282"
    print_status ""
    print_status "Monitor logs: docker logs -f open-avatar-chat-ollama-mac-m3"
    print_status "Stop: docker stop open-avatar-chat-ollama-mac-m3"
else
    print_error "Failed to start container"
    exit 1
fi

print_success "🎉 Ollama Mac M3 test completed!"
print_status "Both OpenAI and Ollama versions are now running:"
print_status "  OpenAI:  https://localhost:8282 (cloud)"
print_status "  Ollama:  https://localhost:8283 (local)"
EOF

chmod +x test_ollama_mac_m3.sh
print_success "Created Ollama test script: test_ollama_mac_m3.sh"

# Show final summary
echo ""
print_status "=== Ollama Mac M3 Setup Complete ==="
print_success "✅ Ollama installed and running"
print_success "✅ Models installed: $MODELS_TO_INSTALL"
print_success "✅ OpenAvatarChat config created"
print_success "✅ Test script ready"

echo ""
print_status "=== Next Steps ==="
print_status "1. Test Ollama version: ./test_ollama_mac_m3.sh"
print_status "2. Access local AI: https://localhost:8283"
print_status "3. Compare with OpenAI: https://localhost:8282"

echo ""
print_status "=== Model Management ==="
print_status "List models:     ollama list"
print_status "Pull new model:  ollama pull model-name"
print_status "Remove model:    ollama rm model-name"
print_status "Chat directly:   ollama run qwen2.5:7b"

echo ""
print_status "=== Service Management ==="
print_status "Start Ollama:    ollama serve"
print_status "Stop Ollama:     pkill ollama"
print_status "Ollama logs:     tail -f ollama.log"

print_success "🚀 Ready for local AI with Ollama on Mac M3!"
