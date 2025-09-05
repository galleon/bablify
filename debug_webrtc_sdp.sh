#!/bin/bash

# WebRTC SDP Debugging Script for OpenAvatarChat
# Diagnoses WebRTC negotiation failures and SDP parsing issues

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
    print_header "WebRTC SDP Debugging Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  test-offer     - Test WebRTC offer/answer negotiation"
    echo "  check-config   - Verify WebRTC configuration"
    echo "  trace-sdp      - Monitor SDP negotiation in real-time"
    echo "  browser-test   - Generate browser-specific test page"
    echo "  fix-cors       - Fix CORS issues for WebRTC"
    echo "  network-test   - Test network connectivity for WebRTC"
    echo "  simple-test    - Create simple WebRTC test without avatar"
    echo ""
}

# Test WebRTC offer/answer
test_webrtc_offer() {
    print_header "Testing WebRTC Offer/Answer Negotiation"

    print_section "Step 1: Check WebRTC Configuration"
    config_response=$(curl -s -k https://localhost:8283/openavatarchat/initconfig 2>/dev/null)

    if echo "$config_response" | grep -q "iceServers"; then
        print_success "WebRTC configuration is accessible"
        echo "$config_response" | python3 -c "
import json, sys
try:
    config = json.load(sys.stdin)
    rtc_config = config.get('rtc_configuration', {})
    if rtc_config:
        print(f'ICE Servers: {len(rtc_config.get(\"iceServers\", []))}')
        for server in rtc_config.get('iceServers', []):
            print(f'  URLs: {server.get(\"urls\", [])}')
    else:
        print('No RTC configuration found')
except:
    print('Error parsing config')
" 2>/dev/null
    else
        print_error "WebRTC configuration not accessible"
        echo "Response: $config_response"
        return 1
    fi

    print_section "Step 2: Test WebRTC Offer Endpoint"
    webrtc_id="debug-$(date +%s)"

    # Create a minimal valid SDP offer
    sdp_offer='v=0
o=- 1234567890 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0
a=ice-ufrag:test
a=ice-pwd:testpassword
m=audio 9 UDP/TLS/RTP/SAVPF 111
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=ice-ufrag:test
a=ice-pwd:testpassword
a=fingerprint:sha-256 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
a=setup:actpass
a=mid:0
a=sendrecv
a=rtcp-mux
a=rtpmap:111 opus/48000/2'

    print_info "Testing with WebRTC ID: $webrtc_id"

    offer_response=$(curl -s -k -X POST https://localhost:8283/webrtc/offer \
        -H "Content-Type: application/json" \
        -d "{
            \"webrtc_id\": \"$webrtc_id\",
            \"sdp\": \"$(echo "$sdp_offer" | tr '\n' ' ')\",
            \"type\": \"offer\"
        }" 2>/dev/null)

    if echo "$offer_response" | grep -q "sdp"; then
        print_success "WebRTC offer accepted"
        echo "$offer_response" | python3 -c "
import json, sys
try:
    response = json.load(sys.stdin)
    print(f'Response type: {response.get(\"type\", \"unknown\")}')
    sdp = response.get('sdp', '')
    if sdp:
        lines = sdp.split(' ')
        print(f'SDP lines: {len([l for l in lines if l.strip()])}')
        if 'audio' in sdp:
            print('✅ Audio supported')
        if 'video' in sdp:
            print('✅ Video supported')
    else:
        print('❌ No SDP in response')
except Exception as e:
    print(f'Error parsing response: {e}')
" 2>/dev/null
    else
        print_error "WebRTC offer failed"
        echo "Response: $offer_response"
    fi
}

# Check WebRTC configuration
check_webrtc_config() {
    print_header "WebRTC Configuration Check"

    print_section "Service Status"
    if curl -s -k https://localhost:8283/ >/dev/null 2>&1; then
        print_success "HTTPS service is accessible"
    else
        print_error "HTTPS service is not accessible"
        return 1
    fi

    print_section "SSL Certificate Check"
    cert_info=$(curl -k -v https://localhost:8283/ 2>&1 | grep -E "(certificate|SSL|TLS)")
    if echo "$cert_info" | grep -q "TLS"; then
        print_success "SSL/TLS is working"
    else
        print_warning "SSL/TLS issues detected"
    fi

    print_section "STUN Server Connectivity"
    stun_servers=("stun.l.google.com:19302" "stun1.l.google.com:19302")
    for server in "${stun_servers[@]}"; do
        if nc -u -z -w 3 ${server/:/ } 2>/dev/null; then
            print_success "STUN server $server is reachable"
        else
            print_warning "STUN server $server may not be reachable"
        fi
    done

    print_section "Browser Compatibility Check"
    print_info "WebRTC requires:"
    echo "  - HTTPS (✅ enabled)"
    echo "  - Modern browser (Chrome 60+, Firefox 55+, Safari 12+)"
    echo "  - Microphone permissions"
    echo "  - No VPN/proxy blocking WebRTC"
}

# Trace SDP negotiation
trace_sdp_negotiation() {
    print_header "Real-time SDP Negotiation Tracing"
    print_info "Monitoring WebRTC offers and responses..."
    print_info "Open browser and try to connect - press Ctrl+C to stop"

    docker compose logs -f open-avatar-chat-ollama 2>/dev/null | grep --line-buffered -E "(webrtc|offer|answer|sdp|ice)" | while read line; do
        timestamp=$(echo "$line" | grep -o "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]")
        if echo "$line" | grep -qi "offer"; then
            print_info "🤝 [$timestamp] WebRTC Offer received"
        elif echo "$line" | grep -qi "answer"; then
            print_success "📋 [$timestamp] WebRTC Answer sent"
        elif echo "$line" | grep -qi "ice"; then
            print_info "🧊 [$timestamp] ICE candidate"
        elif echo "$line" | grep -qi "error"; then
            print_error "💥 [$timestamp] WebRTC Error: $(echo "$line" | cut -d'|' -f4-)"
        else
            echo "🔍 [$timestamp] $(echo "$line" | cut -d'|' -f4- | head -c 100)"
        fi
    done
}

# Generate browser test page
generate_browser_test() {
    print_header "Generating Browser-Specific Test Page"

    cat > webrtc_test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>WebRTC SDP Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
        .info { background: #d1ecf1; color: #0c5460; }
        button { padding: 10px 20px; margin: 10px 0; }
        textarea { width: 100%; height: 200px; }
    </style>
</head>
<body>
    <h1>OpenAvatarChat WebRTC SDP Debugging</h1>

    <div id="status"></div>

    <button onclick="testWebRTC()">Test WebRTC Connection</button>
    <button onclick="testConfig()">Test Configuration</button>
    <button onclick="testMicrophone()">Test Microphone</button>

    <h3>Debug Information:</h3>
    <textarea id="debug" readonly></textarea>

    <script>
        const debug = document.getElementById('debug');
        const status = document.getElementById('status');

        function log(message, type = 'info') {
            const timestamp = new Date().toLocaleTimeString();
            debug.value += `[${timestamp}] ${message}\n`;
            debug.scrollTop = debug.scrollHeight;

            status.innerHTML = `<div class="${type}">${message}</div>`;
            console.log(message);
        }

        async function testConfig() {
            try {
                log('Testing configuration endpoint...', 'info');
                const response = await fetch('/openavatarchat/initconfig');
                const config = await response.json();

                log(`Configuration loaded: ${JSON.stringify(config, null, 2)}`, 'success');

                if (config.rtc_configuration && config.rtc_configuration.iceServers) {
                    log(`Found ${config.rtc_configuration.iceServers.length} ICE servers`, 'success');
                } else {
                    log('No ICE servers configured', 'error');
                }
            } catch (error) {
                log(`Configuration test failed: ${error.message}`, 'error');
            }
        }

        async function testMicrophone() {
            try {
                log('Testing microphone access...', 'info');
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                log('Microphone access granted', 'success');
                stream.getTracks().forEach(track => track.stop());
            } catch (error) {
                log(`Microphone test failed: ${error.message}`, 'error');
            }
        }

        async function testWebRTC() {
            try {
                log('Starting WebRTC test...', 'info');

                // Get configuration
                const configResponse = await fetch('/openavatarchat/initconfig');
                const config = await configResponse.json();

                if (!config.rtc_configuration) {
                    throw new Error('No RTC configuration available');
                }

                // Create RTCPeerConnection
                const pc = new RTCPeerConnection(config.rtc_configuration);

                pc.oniceconnectionstatechange = () => {
                    log(`ICE connection state: ${pc.iceConnectionState}`,
                        pc.iceConnectionState === 'connected' ? 'success' : 'info');
                };

                pc.onconnectionstatechange = () => {
                    log(`Connection state: ${pc.connectionState}`,
                        pc.connectionState === 'connected' ? 'success' : 'info');
                };

                // Get user media
                const stream = await navigator.mediaDevices.getUserMedia({
                    audio: true,
                    video: false
                });

                stream.getTracks().forEach(track => {
                    pc.addTrack(track, stream);
                    log(`Added ${track.kind} track`, 'info');
                });

                // Create offer
                const offer = await pc.createOffer();
                await pc.setLocalDescription(offer);

                log('Created SDP offer', 'info');
                log(`SDP type: ${offer.type}`, 'info');

                // Send offer to server
                const webrtc_id = `test-${Date.now()}`;
                const offerResponse = await fetch('/webrtc/offer', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        webrtc_id: webrtc_id,
                        sdp: offer.sdp,
                        type: offer.type
                    })
                });

                if (!offerResponse.ok) {
                    throw new Error(`Offer failed: ${offerResponse.status} ${offerResponse.statusText}`);
                }

                const answer = await offerResponse.json();
                log('Received SDP answer from server', 'success');

                // Set remote description
                await pc.setRemoteDescription(new RTCSessionDescription({
                    type: answer.type,
                    sdp: answer.sdp
                }));

                log('WebRTC negotiation completed successfully!', 'success');

                // Clean up
                setTimeout(() => {
                    stream.getTracks().forEach(track => track.stop());
                    pc.close();
                    log('WebRTC connection closed', 'info');
                }, 5000);

            } catch (error) {
                log(`WebRTC test failed: ${error.message}`, 'error');
                log(`Error stack: ${error.stack}`, 'error');
            }
        }

        // Auto-run configuration test on load
        window.onload = () => {
            log('WebRTC SDP Test Page Loaded', 'info');
            log(`User Agent: ${navigator.userAgent}`, 'info');
            testConfig();
        };
    </script>
</body>
</html>
EOF

    print_success "Created webrtc_test.html"
    print_info "Open https://localhost:8283/../webrtc_test.html in your browser"
    print_info "Or serve it from a local HTTP server"
}

# Fix CORS issues
fix_cors_issues() {
    print_header "Fixing CORS Issues for WebRTC"

    print_section "Browser Settings Check"
    print_info "For Chrome/Chromium:"
    echo "  1. Go to chrome://flags/"
    echo "  2. Search for 'Insecure origins treated as secure'"
    echo "  3. Add 'https://localhost:8283'"
    echo "  4. Restart browser"

    print_info "For Firefox:"
    echo "  1. Go to about:config"
    echo "  2. Set media.navigator.permission.disabled = true (for testing only)"
    echo "  3. Set media.devices.insecure.enabled = true"

    print_section "Network Configuration"
    print_info "If using VPN or proxy:"
    echo "  - Disable VPN temporarily"
    echo "  - Ensure WebRTC is not blocked"
    echo "  - Check firewall settings"
}

# Network connectivity test
test_network() {
    print_header "Network Connectivity Test"

    print_section "Local Connectivity"
    if curl -s --connect-timeout 5 http://localhost:8283/ >/dev/null; then
        print_success "HTTP connection works"
    else
        print_error "HTTP connection failed"
    fi

    if curl -s -k --connect-timeout 5 https://localhost:8283/ >/dev/null; then
        print_success "HTTPS connection works"
    else
        print_error "HTTPS connection failed"
    fi

    print_section "STUN Server Tests"
    stun_servers=("stun.l.google.com:19302" "stun1.l.google.com:19302")

    for server in "${stun_servers[@]}"; do
        host=$(echo $server | cut -d: -f1)
        port=$(echo $server | cut -d: -f2)

        if timeout 5 nc -u -z $host $port 2>/dev/null; then
            print_success "STUN server $server is reachable"
        else
            print_warning "STUN server $server connectivity issue"
        fi
    done

    print_section "DNS Resolution"
    for host in "stun.l.google.com" "localhost"; do
        if nslookup $host >/dev/null 2>&1; then
            print_success "DNS resolution for $host works"
        else
            print_warning "DNS resolution for $host failed"
        fi
    done
}

# Simple WebRTC test
create_simple_test() {
    print_header "Creating Simple WebRTC Test"

    # Create a minimal test configuration
    cat > config/simple_webrtc_test.yaml << 'EOF'
default:
  logger:
    log_level: "DEBUG"
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
    turn_config:
      turn_provider: "turn_server"
      urls:
        - "stun:stun.l.google.com:19302"
      username: ""
      credential: ""
    handler_configs:
      RtcClient:
        module: client/rtc_client/client_handler_rtc
        connection_ttl: 60
        concurrent_limit: 1
      SileroVad:
        enabled: False
        module: vad/silerovad/vad_handler_silero
      Edge_TTS:
        enabled: False
        module: tts/edgetts/tts_handler_edgetts
      LLMOpenAICompatible:
        enabled: True
        module: llm/openai_compatible/llm_handler_openai_compatible
        model_name: "qwen2.5vl"
        enable_video_input: False
        history_length: 5
        system_prompt: "You are a test AI. Always respond with exactly: 'Test response received successfully.'"
        api_url: "http://ollama:11434/v1"
        api_key: "ollama"
        timeout: 10
        max_retries: 1
        temperature: 0
        max_tokens: 50
        stream: false
      LiteAvatar:
        enabled: False
        module: avatar/liteavatar/avatar_handler_liteavatar
EOF

    print_success "Created simple WebRTC test configuration"
    print_info "To use: cp config/simple_webrtc_test.yaml config/chat_with_ollama_mac_m3.yaml"
    print_info "Then: ./manage.sh restart-ollama"
}

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "This script must be run from the OpenAvatarChat directory"
    exit 1
fi

# Main command dispatcher
case ${1:-help} in
    test-offer)
        test_webrtc_offer
        ;;
    check-config)
        check_webrtc_config
        ;;
    trace-sdp)
        trace_sdp_negotiation
        ;;
    browser-test)
        generate_browser_test
        ;;
    fix-cors)
        fix_cors_issues
        ;;
    network-test)
        test_network
        ;;
    simple-test)
        create_simple_test
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
