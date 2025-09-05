#!/bin/bash

# Simple HTTP Test Server for OpenAvatarChat Debugging
# This script creates a temporary HTTP-only server for testing chat functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

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

# Check if Docker is running
check_docker() {
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not running"
        exit 1
    fi
}

# Check if Ollama is running
check_ollama() {
    if ! curl -s http://localhost:11434/api/tags >/dev/null; then
        print_error "Ollama is not running. Start with: ./manage.sh start-ollama"
        exit 1
    fi
    print_success "Ollama is running"
}

# Start HTTP test server
start_http_server() {
    print_status "Starting HTTP test server on port 8284..."

    # Kill any existing test server
    docker rm -f openavatarchat-http-test 2>/dev/null || true

    # Start new HTTP server
    docker run -d \
        --name openavatarchat-http-test \
        --network openavatarchat_avatar-network \
        -v $(pwd)/config:/config \
        -v $(pwd)/models:/models \
        -v $(pwd)/resource:/resource \
        -v $(pwd)/logs:/logs \
        -p 8284:8282 \
        openavatarchat-open-avatar-chat-ollama \
        /bin/bash -c "cd /root/open-avatar-chat && uv run src/demo.py --config /config/chat_with_ollama_mac_m3_http.yaml"

    print_success "HTTP test server started"
    print_status "Container name: openavatarchat-http-test"
    print_status "Access at: http://localhost:8284"
}

# Wait for server to start
wait_for_server() {
    print_status "Waiting for server to start..."

    for i in {1..30}; do
        if curl -s http://localhost:8284/ >/dev/null 2>&1; then
            print_success "HTTP server is responding"
            return 0
        fi
        echo -n "."
        sleep 2
    done

    print_error "HTTP server did not start within 60 seconds"
    print_status "Check logs: docker logs openavatarchat-http-test"
    return 1
}

# Test basic functionality
test_functionality() {
    print_status "Testing basic functionality..."

    # Test root redirect
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8284/)
    if [[ "$http_code" == "307" ]]; then
        print_success "Root redirect working (HTTP $http_code)"
    else
        print_warning "Unexpected root response: HTTP $http_code"
    fi

    # Test UI access
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8284/ui/index.html)
    if [[ "$http_code" == "200" ]]; then
        print_success "UI accessible (HTTP $http_code)"
    else
        print_error "UI not accessible (HTTP $http_code)"
    fi

    # Test config endpoint
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8284/config)
    if [[ "$http_code" == "200" ]]; then
        print_success "Config endpoint working (HTTP $http_code)"
    else
        print_warning "Config endpoint issue (HTTP $http_code)"
    fi
}

# Show server info
show_info() {
    print_header "HTTP Test Server Information"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Main Interface: http://localhost:8284"
    echo "   Direct UI:      http://localhost:8284/ui/index.html"
    echo "   Config API:     http://localhost:8284/config"
    echo ""
    echo "🔧 Debugging Commands:"
    echo "   View logs:      docker logs -f openavatarchat-http-test"
    echo "   Container info: docker inspect openavatarchat-http-test"
    echo "   Stop server:    docker stop openavatarchat-http-test"
    echo "   Remove server:  docker rm openavatarchat-http-test"
    echo ""
    echo "🚦 Server Status:"
    docker ps --filter "name=openavatarchat-http-test" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    print_warning "This is an HTTP-only server for debugging - not secure!"
    print_status "Use Ctrl+C to stop monitoring, server will keep running"
}

# Monitor logs
monitor_logs() {
    print_status "Monitoring server logs (Ctrl+C to stop)..."
    docker logs -f openavatarchat-http-test
}

# Stop server
stop_server() {
    print_status "Stopping HTTP test server..."
    docker stop openavatarchat-http-test 2>/dev/null || true
    docker rm openavatarchat-http-test 2>/dev/null || true
    print_success "HTTP test server stopped and removed"
}

# Show usage
show_usage() {
    print_header "HTTP Test Server for OpenAvatarChat"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  start     - Start HTTP test server"
    echo "  stop      - Stop HTTP test server"
    echo "  restart   - Restart HTTP test server"
    echo "  logs      - Show/follow server logs"
    echo "  test      - Test server functionality"
    echo "  status    - Show server status and info"
    echo "  help      - Show this help"
    echo ""
    echo "The HTTP server will run on port 8284 (no SSL)"
    echo "This is for debugging SSL/HTTPS issues only"
}

# Main function
main() {
    case ${1:-help} in
        start)
            print_header "Starting HTTP Test Server"
            check_docker
            check_ollama
            start_http_server
            if wait_for_server; then
                test_functionality
                show_info
            fi
            ;;
        stop)
            stop_server
            ;;
        restart)
            print_header "Restarting HTTP Test Server"
            stop_server
            sleep 2
            check_docker
            check_ollama
            start_http_server
            if wait_for_server; then
                test_functionality
                show_info
            fi
            ;;
        logs)
            if docker ps --filter "name=openavatarchat-http-test" --format "{{.Names}}" | grep -q openavatarchat-http-test; then
                monitor_logs
            else
                print_error "HTTP test server is not running"
                print_status "Start it with: $0 start"
            fi
            ;;
        test)
            if docker ps --filter "name=openavatarchat-http-test" --format "{{.Names}}" | grep -q openavatarchat-http-test; then
                print_header "Testing HTTP Server"
                test_functionality
            else
                print_error "HTTP test server is not running"
                print_status "Start it with: $0 start"
            fi
            ;;
        status)
            if docker ps --filter "name=openavatarchat-http-test" --format "{{.Names}}" | grep -q openavatarchat-http-test; then
                show_info
            else
                print_warning "HTTP test server is not running"
                print_status "Start it with: $0 start"
            fi
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
}

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "This script must be run from the OpenAvatarChat directory"
    exit 1
fi

# Run main function with all arguments
main "$@"
