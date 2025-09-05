#!/bin/bash

# OpenAvatarChat Mac M3 Debugging Script
# Comprehensive debugging and monitoring tool for Mac M3 Docker Compose setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show usage
show_usage() {
    print_header "Mac M3 Debug Script for OpenAvatarChat"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  system        - Show Mac M3 system information"
    echo "  performance   - Monitor real-time performance"
    echo "  health        - Comprehensive health check"
    echo "  logs          - Show recent logs with analysis"
    echo "  network       - Test network connectivity"
    echo "  models        - Check model status and performance"
    echo "  troubleshoot  - Run full troubleshooting suite"
    echo "  monitor       - Start continuous monitoring (Ctrl+C to stop)"
    echo "  fix           - Attempt to fix common issues"
    echo "  benchmark     - Run performance benchmarks"
    echo ""
}

# System Information
check_system() {
    print_header "Mac M3 System Information"

    echo "🖥️  Hardware:"
    system_profiler SPHardwareDataType | grep -E "(Chip|Memory|Cores)"

    echo ""
    echo "🐳 Docker Info:"
    docker version --format "Client: {{.Client.Version}} | Server: {{.Server.Version}}"
    docker system df

    echo ""
    echo "💾 Available Resources:"
    echo "Memory: $(vm_stat | awk '/free/ {print $3}' | sed 's/\.//')KB free"
    echo "Disk: $(df -h / | awk 'NR==2 {print $4}') available"

    echo ""
    echo "🔧 Docker Desktop Settings:"
    docker system info | grep -E "(CPUs|Total Memory|Docker Root Dir)"
}

# Performance Monitoring
monitor_performance() {
    print_header "Real-time Performance Monitor"
    print_info "Press Ctrl+C to stop monitoring"

    while true; do
        clear
        echo -e "${CYAN}📊 OpenAvatarChat Performance - $(date)${NC}"
        echo "─────────────────────────────────────────"

        # Container stats
        echo -e "${PURPLE}Container Resources:${NC}"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}"

        echo ""
        echo -e "${PURPLE}Mac M3 System:${NC}"
        echo "CPU Usage: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')%"
        echo "Memory Pressure: $(memory_pressure | tail -1)"

        echo ""
        echo -e "${PURPLE}Service Status:${NC}"
        if curl -s --connect-timeout 2 http://localhost:11434/api/tags >/dev/null; then
            print_success "Ollama API responding"
        else
            print_error "Ollama API not responding"
        fi

        if curl -k -s --connect-timeout 2 https://localhost:8283/ >/dev/null; then
            print_success "Web interface responding"
        else
            print_error "Web interface not responding"
        fi

        sleep 5
    done
}

# Health Check
health_check() {
    print_header "Comprehensive Health Check"

    print_section "Docker Services"
    docker compose --profile ollama ps

    echo ""
    print_section "Service Health"

    # Check Ollama API
    if curl -s --connect-timeout 5 http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_success "Ollama API is healthy"

        # Get model list
        models=$(curl -s http://localhost:11434/api/tags | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    models = [m['name'] for m in data.get('models', [])]
    print(f'Models loaded: {len(models)} - {models}')
except:
    print('Error parsing models')
" 2>/dev/null)
        print_info "$models"
    else
        print_error "Ollama API is not responding"
    fi

    # Check Web Interface
    if curl -k -s --connect-timeout 5 https://localhost:8283/ >/dev/null 2>&1; then
        print_success "Web interface is healthy"
    else
        print_error "Web interface is not responding"
    fi

    # Check Redis
    if docker compose exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
        print_success "Redis is healthy"
    else
        print_warning "Redis might have issues"
    fi

    echo ""
    print_section "Resource Usage"
    docker stats --no-stream --format "{{.Name}}: CPU={{.CPUPerc}} MEM={{.MemUsage}} ({{.MemPerc}})"

    echo ""
    print_section "Disk Usage"
    echo "Docker system: $(docker system df --format 'Images: {{.ImagesSize}}, Containers: {{.ContainersSize}}, Volumes: {{.VolumesSize}}')"
    echo "Project directory: $(du -sh . | awk '{print $1}')"
    echo "Models directory: $(du -sh models 2>/dev/null | awk '{print $1}' || echo 'N/A')"
}

# Log Analysis
analyze_logs() {
    print_header "Recent Logs Analysis"

    print_section "OpenAvatarChat Service Logs (Last 50 lines)"
    docker compose logs --tail 50 open-avatar-chat-ollama | tail -20

    echo ""
    print_section "Ollama Server Logs (Last 30 lines)"
    docker compose logs --tail 30 ollama | tail -15

    echo ""
    print_section "Error Detection"
    error_count=$(docker compose logs --tail 100 2>/dev/null | grep -i error | wc -l)
    if [ "$error_count" -gt 0 ]; then
        print_warning "Found $error_count error messages in recent logs"
        docker compose logs --tail 100 2>/dev/null | grep -i error | tail -5
    else
        print_success "No errors found in recent logs"
    fi

    warning_count=$(docker compose logs --tail 100 2>/dev/null | grep -i warning | wc -l)
    if [ "$warning_count" -gt 0 ]; then
        print_info "Found $warning_count warning messages"
    fi
}

# Network Connectivity
test_network() {
    print_header "Network Connectivity Test"

    print_section "Internal Container Network"

    # Test container-to-container communication
    if docker compose exec -T open-avatar-chat-ollama curl -s http://ollama:11434/api/tags >/dev/null 2>&1; then
        print_success "OpenAvatarChat → Ollama communication: OK"
    else
        print_error "OpenAvatarChat → Ollama communication: FAILED"
    fi

    if docker compose exec -T open-avatar-chat-ollama curl -s redis:6379 >/dev/null 2>&1; then
        print_success "OpenAvatarChat → Redis communication: OK"
    else
        print_warning "OpenAvatarChat → Redis communication: FAILED (non-critical)"
    fi

    print_section "External Network Access"

    # Test external connectivity from containers
    if docker compose exec -T ollama ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Ollama container has internet access"
    else
        print_warning "Ollama container cannot reach internet (may affect model downloads)"
    fi

    print_section "Port Accessibility"

    ports=("11434:Ollama API" "8283:Web Interface" "6379:Redis")
    for port_info in "${ports[@]}"; do
        port=$(echo $port_info | cut -d: -f1)
        service=$(echo $port_info | cut -d: -f2)

        if nc -z localhost $port 2>/dev/null; then
            print_success "Port $port ($service): Open"
        else
            print_error "Port $port ($service): Closed"
        fi
    done
}

# Model Status
check_models() {
    print_header "Model Status and Performance"

    print_section "Installed Models"
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        curl -s http://localhost:11434/api/tags | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    models = data.get('models', [])
    print(f'Total models: {len(models)}')
    print()
    for model in models:
        name = model.get('name', 'Unknown')
        size = model.get('size', 0)
        size_gb = size / (1024**3) if size > 0 else 0
        modified = model.get('modified_at', 'Unknown')
        print(f'📦 {name}')
        print(f'   Size: {size_gb:.1f} GB')
        print(f'   Modified: {modified[:19] if modified != \"Unknown\" else \"Unknown\"}')
        print()
except Exception as e:
    print(f'Error parsing models: {e}')
"
    else
        print_error "Cannot connect to Ollama API"
    fi

    print_section "Model Performance Test"
    print_info "Testing qwen2.5vl model response time..."

    start_time=$(date +%s%N)
    response=$(curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen2.5vl",
            "prompt": "Hello! This is a test. Respond with just: Test successful.",
            "stream": false
        }' 2>/dev/null)
    end_time=$(date +%s%N)

    if echo "$response" | grep -q "successful"; then
        duration=$(( (end_time - start_time) / 1000000 ))
        print_success "Model response time: ${duration}ms"
    else
        print_error "Model test failed"
    fi
}

# Troubleshooting Suite
run_troubleshooting() {
    print_header "Full Troubleshooting Suite"

    print_section "1. System Requirements Check"

    # Check Docker version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "error")
    if [[ "$docker_version" != "error" ]]; then
        print_success "Docker version: $docker_version"
    else
        print_error "Docker is not running or accessible"
        return 1
    fi

    # Check available memory
    available_memory=$(vm_stat | awk '/free/ {print int($3 * 4096 / 1024 / 1024)}')
    if [[ $available_memory -gt 8192 ]]; then
        print_success "Available memory: ${available_memory}MB"
    else
        print_warning "Low available memory: ${available_memory}MB (recommend >8GB)"
    fi

    print_section "2. Service Dependencies"

    # Check if services are running
    services=("ollama" "open-avatar-chat-ollama" "redis")
    for service in "${services[@]}"; do
        if docker compose ps $service | grep -q "Up"; then
            print_success "Service $service is running"
        else
            print_error "Service $service is not running"
            echo "  Try: docker compose --profile ollama up -d $service"
        fi
    done

    print_section "3. Configuration Validation"

    # Check if config files exist
    config_files=("config/chat_with_ollama_mac_m3.yaml" "docker-compose.yml")
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            print_success "Config file exists: $config"
        else
            print_error "Missing config file: $config"
        fi
    done

    print_section "4. Network Connectivity"
    test_network

    print_section "5. Performance Check"
    docker stats --no-stream --format "{{.Name}}: CPU={{.CPUPerc}} MEM={{.MemPerc}}" | head -5
}

# Fix Common Issues
fix_issues() {
    print_header "Attempting to Fix Common Issues"

    print_section "1. Restarting Services"
    print_info "Stopping services..."
    docker compose --profile ollama down

    print_info "Waiting 5 seconds..."
    sleep 5

    print_info "Starting services..."
    docker compose --profile ollama up -d

    print_success "Services restarted"

    print_section "2. Clearing Docker Cache"
    docker system prune -f
    print_success "Docker cache cleared"

    print_section "3. Regenerating SSL Certificates"
    if [[ -d "ssl_certs" ]]; then
        rm -rf ssl_certs/*
        print_info "SSL certificates cleared"
    fi

    print_section "4. Checking Service Health (waiting 30s)"
    sleep 30
    health_check
}

# Performance Benchmarks
run_benchmarks() {
    print_header "Performance Benchmarks"

    print_section "System Benchmarks"

    # CPU benchmark
    print_info "Running CPU benchmark..."
    time_result=$(time -p sh -c 'for i in $(seq 1 100000); do echo $i >/dev/null; done' 2>&1 | grep real | awk '{print $2}')
    print_info "CPU test (100k iterations): ${time_result}s"

    # Memory benchmark
    print_info "Current memory usage:"
    vm_stat | head -5

    print_section "Model Performance Benchmarks"

    # Test model loading time
    print_info "Testing model loading time..."
    start_time=$(date +%s)

    curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d '{
            "model": "qwen2.5vl",
            "prompt": "Generate a short creative story about AI and humans working together.",
            "stream": false
        }' >/dev/null 2>&1

    end_time=$(date +%s)
    duration=$((end_time - start_time))
    print_info "Model generation time: ${duration}s"

    print_section "Container Performance"
    print_info "Container resource usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
}

# Main function
main() {
    case ${1:-help} in
        system)
            check_system
            ;;
        performance)
            monitor_performance
            ;;
        health)
            health_check
            ;;
        logs)
            analyze_logs
            ;;
        network)
            test_network
            ;;
        models)
            check_models
            ;;
        troubleshoot)
            run_troubleshooting
            ;;
        monitor)
            monitor_performance
            ;;
        fix)
            fix_issues
            ;;
        benchmark)
            run_benchmarks
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo "Unknown command: $1"
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
