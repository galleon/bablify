#!/bin/bash

# Chat Pipeline Debugging Script for OpenAvatarChat
# Traces message flow from WebRTC input to LLM response and TTS output

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_section() {
    echo -e "${PURPLE}--- $1 ---${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Show usage
show_usage() {
    print_header "Chat Pipeline Debugging Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  trace         - Start real-time message tracing"
    echo "  test-llm      - Test LLM handler directly"
    echo "  test-tts      - Test TTS handler"
    echo "  test-vad      - Test VAD (Voice Activity Detection)"
    echo "  test-webrtc   - Test WebRTC message flow"
    echo "  pipeline      - Test entire pipeline step by step"
    echo "  analyze       - Analyze recent chat attempts"
    echo "  monitor       - Monitor all components simultaneously"
    echo "  simulate      - Simulate a chat message through the system"
    echo ""
}

# Test LLM Handler
test_llm() {
    print_header "Testing LLM Handler"

    print_section "Direct Ollama API Test"
    start_time=$(date +%s%N)
    response=$(curl -s -X POST http://localhost:11434/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ollama" \
        -d '{
            "model": "qwen2.5vl",
            "messages": [{"role": "user", "content": "Say: Pipeline test successful"}],
            "stream": false
        }')
    end_time=$(date +%s%N)

    if echo "$response" | grep -q "Pipeline test successful"; then
        duration=$(( (end_time - start_time) / 1000000 ))
        print_success "LLM responds correctly in ${duration}ms"
    else
        print_error "LLM response failed"
        echo "$response" | head -3
    fi
}

# Test TTS
test_tts() {
    print_header "Testing TTS Handler"

    print_section "EdgeTTS Service Test"
    # Check if we can access TTS indirectly by checking logs
    print_info "TTS is integrated into the chat pipeline"
    print_info "Check logs for TTS activity: ./manage.sh logs-ollama | grep -i tts"

    # Test if Edge TTS is working by checking system
    if command -v edge-tts >/dev/null 2>&1; then
        print_success "EdgeTTS is available on system"
    else
        print_warning "EdgeTTS not found in system PATH (but may be in container)"
    fi
}

# Test VAD
test_vad() {
    print_header "Testing VAD (Voice Activity Detection)"

    print_section "VAD Configuration"
    # Check VAD settings from logs
    vad_config=$(docker compose logs open-avatar-chat-ollama 2>/dev/null | grep "SileroVad" | tail -1)
    if [[ -n "$vad_config" ]]; then
        print_success "VAD handler loaded"
        echo "$vad_config"
    else
        print_error "VAD handler not found in logs"
    fi

    print_section "VAD Activity Check"
    print_info "Look for these patterns when speaking:"
    echo "  - 'Pre start of new human speech'"
    echo "  - 'Start of human speech'"
    echo "  - 'End of human speech'"
    print_info "Monitor with: ./manage.sh logs-ollama | grep -i 'speech\\|vad'"
}

# Test WebRTC
test_webrtc() {
    print_header "Testing WebRTC Message Flow"

    print_section "WebRTC Configuration"
    config=$(curl -s -k https://localhost:8283/openavatarchat/initconfig 2>/dev/null)
    if echo "$config" | grep -q "iceServers"; then
        print_success "WebRTC configuration is valid"
        echo "$config" | python3 -c "import json, sys; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "$config"
    else
        print_error "WebRTC configuration is invalid"
        echo "$config"
    fi

    print_section "WebRTC Connection Test"
    # Check for WebRTC offers in logs
    webrtc_offers=$(docker compose logs open-avatar-chat-ollama 2>/dev/null | grep "POST /webrtc/offer" | wc -l | tr -d ' ')
    if [[ "$webrtc_offers" -gt 0 ]]; then
        print_success "WebRTC offers detected: $webrtc_offers"
    else
        print_warning "No WebRTC offers found in logs"
    fi
}

# Analyze recent chat attempts
analyze_recent() {
    print_header "Analyzing Recent Chat Attempts"

    print_section "Message Flow Analysis"

    # Check for incoming messages
    chat_messages=$(docker compose logs open-avatar-chat-ollama 2>/dev/null | grep -E "(chat|message|Custom:)" | tail -10)
    if [[ -n "$chat_messages" ]]; then
        print_success "Found recent chat messages:"
        echo "$chat_messages"
    else
        print_warning "No chat messages found in recent logs"
    fi

    echo ""
    print_section "Error Analysis"

    # Check for errors
    errors=$(docker compose logs open-avatar-chat-ollama 2>/dev/null | grep -i "error\|exception\|failed" | tail -5)
    if [[ -n "$errors" ]]; then
        print_warning "Found errors:"
        echo "$errors"
    else
        print_success "No errors found in recent logs"
    fi

    echo ""
    print_section "Timeout Analysis"

    # Check for timeouts
    timeouts=$(docker compose logs open-avatar-chat-ollama 2>/dev/null | grep -i "timeout" | tail -5)
    if [[ -n "$timeouts" ]]; then
        print_warning "Found timeouts:"
        echo "$timeouts"
    else
        print_success "No timeouts found in recent logs"
    fi
}

# Real-time message tracing
trace_messages() {
    print_header "Real-time Message Tracing"
    print_info "Monitoring chat pipeline... Try sending a message now!"
    print_info "Press Ctrl+C to stop"

    # Monitor specific patterns
    docker compose logs -f open-avatar-chat-ollama 2>/dev/null | grep --line-buffered -E "(Custom:|chat|speech|LLM|TTS|response|message)" | while read line; do
        timestamp=$(echo "$line" | grep -o "2025-[0-9-]* [0-9:]*\.[0-9]*")
        content=$(echo "$line" | sed 's/.*| //')

        if echo "$content" | grep -q "Custom:"; then
            print_success "📨 Message received: $content"
        elif echo "$content" | grep -q "speech"; then
            print_info "🎤 Speech detected: $content"
        elif echo "$content" | grep -q "LLM"; then
            print_info "🧠 LLM processing: $content"
        elif echo "$content" | grep -q "TTS"; then
            print_info "🔊 TTS processing: $content"
        elif echo "$content" | grep -q "response"; then
            print_success "📤 Response: $content"
        else
            echo "⚡ $timestamp: $content"
        fi
    done
}

# Monitor all components
monitor_all() {
    print_header "Monitoring All Components"
    print_info "Starting comprehensive monitoring..."
    print_info "Try chatting now - all activity will be tracked"
    print_info "Press Ctrl+C to stop"

    # Use multiple grep patterns to catch everything
    docker compose logs -f open-avatar-chat-ollama 2>/dev/null | grep --line-buffered -E "(INFO|ERROR|WARNING)" | while read line; do
        if echo "$line" | grep -q "Custom:"; then
            print_success "📨 MESSAGE: $(echo "$line" | grep -o 'Custom:.*')"
        elif echo "$line" | grep -qi "speech"; then
            print_info "🎤 SPEECH: $(echo "$line" | cut -d'|' -f4-)"
        elif echo "$line" | grep -qi "llm\|openai"; then
            print_info "🧠 LLM: $(echo "$line" | cut -d'|' -f4-)"
        elif echo "$line" | grep -qi "tts\|edge"; then
            print_info "🔊 TTS: $(echo "$line" | cut -d'|' -f4-)"
        elif echo "$line" | grep -qi "error"; then
            print_error "💥 ERROR: $(echo "$line" | cut -d'|' -f4-)"
        elif echo "$line" | grep -qi "timeout"; then
            print_warning "⏰ TIMEOUT: $(echo "$line" | cut -d'|' -f4-)"
        elif echo "$line" | grep -qi "webrtc\|rtc"; then
            print_info "📡 WebRTC: $(echo "$line" | cut -d'|' -f4-)"
        else
            # Show timestamp and last part
            timestamp=$(echo "$line" | grep -o "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]")
            content=$(echo "$line" | cut -d'|' -f4- | sed 's/^ *//')
            if [[ -n "$content" && ${#content} -lt 200 ]]; then
                echo "⚡ [$timestamp] $content"
            fi
        fi
    done
}

# Test entire pipeline
test_pipeline() {
    print_header "Testing Entire Chat Pipeline"

    print_section "Step 1: WebRTC Configuration"
    test_webrtc

    echo ""
    print_section "Step 2: LLM Handler"
    test_llm

    echo ""
    print_section "Step 3: TTS Handler"
    test_tts

    echo ""
    print_section "Step 4: VAD Handler"
    test_vad

    echo ""
    print_section "Step 5: Recent Activity Analysis"
    analyze_recent

    echo ""
    print_header "Pipeline Test Summary"
    print_info "If all components are working, try these debugging steps:"
    echo "1. Open browser console (F12) and check for JavaScript errors"
    echo "2. Ensure microphone permissions are granted"
    echo "3. Try typing a message first (bypasses VAD)"
    echo "4. Monitor with: $0 trace"
    echo "5. Check if responses are being generated but not displayed"
}

# Simulate message
simulate_message() {
    print_header "Simulating Chat Message"

    print_section "Testing Message Injection"
    print_info "This will attempt to simulate a WebRTC message"

    # Try to send a test message via WebRTC endpoint
    webrtc_id="test-$(date +%s)"

    print_info "Attempting WebRTC offer with ID: $webrtc_id"
    response=$(curl -s -k -X POST https://localhost:8283/webrtc/offer \
        -H "Content-Type: application/json" \
        -d "{\"webrtc_id\": \"$webrtc_id\", \"sdp\": \"test-sdp\", \"type\": \"offer\"}" 2>/dev/null)

    if echo "$response" | grep -q "sdp"; then
        print_success "WebRTC offer accepted"
        echo "$response" | python3 -c "import json, sys; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null
    else
        print_warning "WebRTC offer response:"
        echo "$response"
    fi
}

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "This script must be run from the OpenAvatarChat directory"
    exit 1
fi

# Check if services are running
if ! docker compose ps open-avatar-chat-ollama | grep -q "Up"; then
    print_error "OpenAvatarChat service is not running"
    print_info "Start it with: ./manage.sh start-ollama"
    exit 1
fi

# Main command dispatcher
case ${1:-help} in
    trace)
        trace_messages
        ;;
    test-llm)
        test_llm
        ;;
    test-tts)
        test_tts
        ;;
    test-vad)
        test_vad
        ;;
    test-webrtc)
        test_webrtc
        ;;
    pipeline)
        test_pipeline
        ;;
    analyze)
        analyze_recent
        ;;
    monitor)
        monitor_all
        ;;
    simulate)
        simulate_message
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
