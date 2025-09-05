#!/bin/bash

# OpenAI Mac M3 Diagnostic Script
# Troubleshoot OpenAvatarChat OpenAI Version Issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[DIAGNOSTIC]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo ""
    echo "==========================================="
    echo -e "${BLUE}$1${NC}"
    echo "==========================================="
}

# Check if container is running
print_section "CONTAINER STATUS CHECK"

if docker ps --format "table {{.Names}}" | grep -q "open-avatar-chat-mac-m3"; then
    print_success "Container is running"

    CONTAINER_STATS=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" open-avatar-chat-mac-m3)
    echo "$CONTAINER_STATS"
else
    print_error "Container is not running"
    echo "Available containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi

# Check recent logs for errors
print_section "ERROR LOG ANALYSIS"

RECENT_LOGS=$(docker logs --tail 50 open-avatar-chat-mac-m3 2>&1)

if echo "$RECENT_LOGS" | grep -qi "error\|exception\|failed\|timeout"; then
    print_warning "Found potential issues in logs:"
    echo "$RECENT_LOGS" | grep -i "error\|exception\|failed\|timeout" | tail -10
else
    print_success "No obvious errors in recent logs"
fi

# Check if handlers are loaded
print_section "HANDLER STATUS CHECK"

if echo "$RECENT_LOGS" | grep -q "Registered handler.*LLMOpenAICompatible"; then
    print_success "OpenAI LLM handler loaded"

    # Extract handler config from logs
    LLM_CONFIG=$(echo "$RECENT_LOGS" | grep "LLMOpenAICompatible" | tail -1)
    echo "Config: $LLM_CONFIG"

    # Check if API key is present
    if echo "$LLM_CONFIG" | grep -q "api_key=None"; then
        print_error "API key is NULL - this is the main issue!"
        echo "The OpenAI handler is not receiving the API key properly."
    elif echo "$LLM_CONFIG" | grep -q "api_key="; then
        print_success "API key is present in handler config"
    fi
else
    print_error "OpenAI LLM handler not found in logs"
fi

# Check other handlers
HANDLERS=("RtcClient" "SileroVad" "Edge_TTS")
for handler in "${HANDLERS[@]}"; do
    if echo "$RECENT_LOGS" | grep -q "Registered handler.*$handler"; then
        print_success "$handler handler loaded"
    else
        print_error "$handler handler not loaded"
    fi
done

# Test web interface connectivity
print_section "WEB INTERFACE TEST"

for port in 8282; do
    for protocol in https http; do
        if curl -k -s --connect-timeout 3 ${protocol}://localhost:${port}/ > /dev/null 2>&1; then
            print_success "${protocol}://localhost:${port}/ is accessible"
        else
            print_error "${protocol}://localhost:${port}/ is not accessible"
        fi
    done
done

# Test OpenAI API directly
print_section "OPENAI API TEST"

if [[ -f ".env" ]] && grep -q "OPENAI_API_KEY" .env; then
    source .env

    if [[ -n "$OPENAI_API_KEY" && "$OPENAI_API_KEY" != "your_openai_api_key_here" ]]; then
        print_status "Testing OpenAI API directly..."

        API_RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $OPENAI_API_KEY" \
                           -H "Content-Type: application/json" \
                           -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"Hello"}],"max_tokens":10}' \
                           https://api.openai.com/v1/chat/completions)

        HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
        RESPONSE_BODY=$(echo "$API_RESPONSE" | head -n -1)

        if [[ "$HTTP_CODE" == "200" ]]; then
            print_success "OpenAI API is working correctly"
            echo "Response preview: $(echo "$RESPONSE_BODY" | head -c 100)..."
        else
            print_error "OpenAI API failed with HTTP $HTTP_CODE"
            echo "Error response: $RESPONSE_BODY"
        fi
    else
        print_error "OPENAI_API_KEY not set or invalid in .env file"
    fi
else
    print_error ".env file not found or doesn't contain OPENAI_API_KEY"
fi

# Check container environment variables
print_section "CONTAINER ENVIRONMENT CHECK"

CONTAINER_ENV=$(docker exec open-avatar-chat-mac-m3 env | grep -E "(OPENAI|API)" || echo "No API keys found in container environment")
if [[ "$CONTAINER_ENV" == "No API keys found in container environment" ]]; then
    print_error "OpenAI API key not found in container environment"
    print_status "This is likely the root cause of the issue!"
else
    print_success "API key environment variables found in container"
    echo "$CONTAINER_ENV" | sed 's/=.*/=***HIDDEN***/'
fi

# Check config file in container
print_section "CONFIG FILE CHECK"

print_status "Checking config file in container..."
CONFIG_CONTENT=$(docker exec open-avatar-chat-mac-m3 cat /root/open-avatar-chat/config/temp_openai_config.yaml 2>/dev/null || echo "Config file not found")

if [[ "$CONFIG_CONTENT" == "Config file not found" ]]; then
    print_error "Config file not found in container"
    print_status "Available configs:"
    docker exec open-avatar-chat-mac-m3 ls -la /root/open-avatar-chat/config/
else
    print_success "Config file found in container"

    # Check if API key is in config
    if echo "$CONFIG_CONTENT" | grep -q "api_key.*\$OPENAI_API_KEY"; then
        print_success "Config references OPENAI_API_KEY environment variable"
    elif echo "$CONFIG_CONTENT" | grep -q "api_key.*sk-"; then
        print_success "Config contains direct API key"
    else
        print_error "Config doesn't seem to have proper API key setup"
        echo "API key line in config:"
        echo "$CONFIG_CONTENT" | grep -A2 -B2 "api_key" || echo "No api_key found in config"
    fi
fi

# Real-time log monitoring
print_section "REAL-TIME ISSUE DETECTION"

print_status "Monitoring logs for 10 seconds to detect real-time issues..."
print_status "Try to send a message in the web interface now..."

timeout 10 docker logs -f open-avatar-chat-mac-m3 2>&1 | while read line; do
    echo "$(date '+%H:%M:%S'): $line"

    # Check for specific issues
    if echo "$line" | grep -qi "api_key.*required"; then
        print_error "FOUND ISSUE: API key is required but not provided!"
    elif echo "$line" | grep -qi "unauthorized\|401"; then
        print_error "FOUND ISSUE: API key is invalid or unauthorized!"
    elif echo "$line" | grep -qi "timeout\|connection.*refused"; then
        print_error "FOUND ISSUE: Network connectivity problem!"
    elif echo "$line" | grep -qi "exception\|error"; then
        print_warning "FOUND ISSUE: $(echo "$line" | grep -o 'Exception.*\|Error.*')"
    fi
done 2>/dev/null || true

print_section "DIAGNOSTIC SUMMARY"

echo ""
print_status "=== LIKELY ISSUES AND SOLUTIONS ==="

# Check the most common issues
ISSUES_FOUND=false

# Issue 1: API key not in container environment
CONTAINER_API_KEY=$(docker exec open-avatar-chat-mac-m3 printenv OPENAI_API_KEY 2>/dev/null || echo "")
if [[ -z "$CONTAINER_API_KEY" ]]; then
    print_error "1. OPENAI_API_KEY not found in container environment"
    echo "   SOLUTION: Restart container with proper environment variable:"
    echo "   docker rm -f open-avatar-chat-mac-m3"
    echo "   ./test_openai_mac_m3.sh"
    ISSUES_FOUND=true
fi

# Issue 2: Config file API key setup
if echo "$CONFIG_CONTENT" | grep -q "api_key.*\$OPENAI_API_KEY" && [[ -z "$CONTAINER_API_KEY" ]]; then
    print_error "2. Config expects environment variable but it's not set in container"
    echo "   SOLUTION: Fix environment variable passing to container"
    ISSUES_FOUND=true
fi

# Issue 3: Handler not receiving API key
if echo "$RECENT_LOGS" | grep -q "api_key=None"; then
    print_error "3. Handler receiving NULL API key"
    echo "   SOLUTION: Fix API key propagation from config to handler"
    ISSUES_FOUND=true
fi

if [[ "$ISSUES_FOUND" == "false" ]]; then
    print_success "No obvious configuration issues found"
    print_status "The issue might be:"
    echo "   - Network connectivity to OpenAI API"
    echo "   - Processing timeout in message handling"
    echo "   - Browser/WebRTC related issue"
    echo ""
    print_status "Try these steps:"
    echo "   1. Refresh the browser page: https://localhost:8282"
    echo "   2. Clear browser cache and try again"
    echo "   3. Try a simple text message instead of voice"
    echo "   4. Check browser console for JavaScript errors"
fi

print_section "QUICK FIXES"

echo ""
print_status "=== QUICK FIXES TO TRY ==="
echo "1. Restart with fresh environment:"
echo "   docker rm -f open-avatar-chat-mac-m3"
echo "   ./test_openai_mac_m3.sh"
echo ""
echo "2. Test API key manually:"
echo "   source .env"
echo "   curl -H \"Authorization: Bearer \$OPENAI_API_KEY\" https://api.openai.com/v1/models"
echo ""
echo "3. Check browser console for errors at: https://localhost:8282"
echo ""
echo "4. Try simple text chat instead of voice input"
echo ""
echo "5. Monitor real-time logs while testing:"
echo "   docker logs -f open-avatar-chat-mac-m3"

print_section "DIAGNOSTIC COMPLETE"
echo "Review the findings above to identify and fix the issue."
