#!/bin/bash

# Advanced Management Script for Mac M3 Max OpenAvatarChat
# Comprehensive control and monitoring for Apple Silicon optimization
# Version 2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="open-avatar-chat-mac-m3-advanced"
IMAGE_NAME="open-avatar-chat:mac-m3-advanced"
COMPOSE_FILE="docker-compose.mac-m3-advanced.yml"
CONFIG_FILE="config/chat_with_minicpm_mac_m3_advanced.yaml"
LOG_FILE="logs/manage_mac_m3.log"
MONITORING_ENABLED=false
VERBOSE=false

# Function to print colored output
print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

print_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" >> "$LOG_FILE"
    fi
}

print_metric() {
    echo -e "${PURPLE}[METRIC]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << 'EOF'
Advanced Mac M3 Management Script for OpenAvatarChat v2.0

USAGE:
    ./manage_mac_m3_advanced.sh [COMMAND] [OPTIONS]

COMMANDS:
    Container Management:
        start              Start the application stack
        stop               Stop the application stack
        restart            Restart the application stack
        status             Show container status and health
        logs               Show container logs
        shell              Enter container shell

    Build & Deploy:
        build              Build the Docker image
        rebuild            Clean build from scratch
        deploy             Deploy with Docker Compose
        update             Update and redeploy

    Monitoring & Debugging:
        monitor            Show real-time system metrics
        health             Check application health
        debug              Enable debug mode and show diagnostics
        profile            Show performance profiling
        metrics            Display Mac M3 performance metrics

    Maintenance:
        cleanup            Clean up unused containers and images
        backup             Backup configuration and data
        restore            Restore from backup
        reset              Reset to clean state

    Configuration:
        config             Show current configuration
        validate           Validate configuration files
        optimize           Apply Mac M3 optimizations
        tune               Auto-tune performance settings

    System:
        requirements       Check system requirements
        benchmark          Run performance benchmark
        thermal            Check thermal status
        memory             Show memory usage analysis

OPTIONS:
    --verbose, -v       Enable verbose output
    --monitoring        Enable monitoring mode
    --config FILE       Use specific config file
    --compose FILE      Use specific compose file
    --dry-run           Show what would be done without executing
    --help, -h          Show this help message

EXAMPLES:
    # Start with monitoring enabled
    ./manage_mac_m3_advanced.sh start --monitoring

    # Debug with verbose output
    ./manage_mac_m3_advanced.sh debug --verbose

    # Build and deploy with custom config
    ./manage_mac_m3_advanced.sh deploy --config config/my_config.yaml

    # Check performance metrics
    ./manage_mac_m3_advanced.sh metrics

    # Full system optimization
    ./manage_mac_m3_advanced.sh optimize --verbose

ENVIRONMENT VARIABLES:
    MAC_M3_MEMORY_GB    Available memory for optimization (default: auto-detect)
    MAC_M3_CPU_CORES    Number of CPU cores (default: auto-detect)
    ENABLE_MONITORING   Enable monitoring services (default: false)
    DEBUG_LEVEL         Debug output level (default: info)

EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_debug "Checking prerequisites..."

    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        print_warning "This script is optimized for macOS (current: $(uname))"
    fi

    # Check architecture
    if [[ "$(uname -m)" != "arm64" ]]; then
        print_warning "Architecture $(uname -m) detected. Optimized for Apple Silicon (arm64)"
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose not found. Using 'docker compose' instead."
    fi

    # Create necessary directories
    mkdir -p logs models ssl_certs resource temp data/{redis,prometheus,grafana} cache monitoring/grafana/{dashboards,datasources}

    print_debug "Prerequisites check completed"
}

# Function to get system information
get_system_info() {
    local memory_gb=$(sysctl hw.memsize 2>/dev/null | awk '{print int($2/1024/1024/1024)}' || echo "unknown")
    local cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
    local cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
    local os_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")

    echo "System Information:"
    echo "  OS: macOS $os_version"
    echo "  CPU: $cpu_brand"
    echo "  CPU Cores: $cpu_cores"
    echo "  Memory: ${memory_gb}GB"
    echo "  Architecture: $(uname -m)"
    echo "  Docker: $docker_version"
}

# Function to check container status
check_container_status() {
    local container=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        echo "running"
    elif docker ps -a --format "table {{.Names}}" | grep -q "^${container}$"; then
        echo "stopped"
    else
        echo "not_found"
    fi
}

# Function to show container health
show_health() {
    print_header "=== Container Health Status ==="

    local containers=("$CONTAINER_NAME" "avatar-redis" "avatar-prometheus" "avatar-grafana" "avatar-nginx")

    for container in "${containers[@]}"; do
        local status=$(check_container_status "$container")
        case $status in
            "running")
                local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
                if [[ "$health" == "healthy" ]]; then
                    print_success "$container: Running (Healthy)"
                elif [[ "$health" == "unhealthy" ]]; then
                    print_error "$container: Running (Unhealthy)"
                else
                    print_status "$container: Running (No health check)"
                fi
                ;;
            "stopped")
                print_warning "$container: Stopped"
                ;;
            "not_found")
                print_warning "$container: Not found"
                ;;
        esac
    done

    # Check service endpoints
    echo ""
    print_header "=== Service Endpoints ==="
    local endpoints=(
        "Main Application:https://localhost:8282"
        "Health Check:http://localhost:8282/health"
        "Metrics:http://localhost:8283/metrics"
        "Prometheus:http://localhost:9090"
        "Grafana:http://localhost:3000"
        "Redis:localhost:6379"
    )

    for endpoint in "${endpoints[@]}"; do
        local name="${endpoint%%:*}"
        local url="${endpoint#*:}"

        if [[ "$url" =~ ^https?:// ]]; then
            if curl -k -s --max-time 5 --connect-timeout 2 "$url" &> /dev/null; then
                print_success "$name: $url (Accessible)"
            else
                print_error "$name: $url (Not accessible)"
            fi
        else
            print_status "$name: $url"
        fi
    done
}

# Function to show system metrics
show_metrics() {
    print_header "=== Mac M3 Performance Metrics ==="

    # System metrics
    local memory_pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' || echo "N/A")
    local thermal_state=$(pmset -g thermlog 2>/dev/null | grep -E "CPU_Speed_Limit|GPU_Speed_Limit" | tail -2 || echo "N/A")

    echo "System Metrics:"
    echo "  Memory Pressure: $memory_pressure"
    echo "  Thermal State: Available via pmset -g thermlog"

    # Docker container metrics
    if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo ""
        echo "Container Metrics:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$CONTAINER_NAME"

        # Application-specific metrics
        if curl -k -s --max-time 5 http://localhost:8283/metrics &> /dev/null; then
            echo ""
            echo "Application Metrics:"
            curl -k -s --max-time 5 http://localhost:8283/metrics | grep -E "(avatar_|mac_m3_)" | head -10 || echo "  Metrics not available"
        fi
    else
        print_warning "Container not running - no metrics available"
    fi
}

# Function to optimize system for Mac M3
optimize_system() {
    print_header "=== Applying Mac M3 Optimizations ==="

    # Check available memory and adjust limits
    local memory_gb=$(sysctl hw.memsize 2>/dev/null | awk '{print int($2/1024/1024/1024)}' || echo "16")
    local cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "8")

    print_status "Detected: ${memory_gb}GB RAM, ${cpu_cores} CPU cores"

    # Create optimized environment file
    cat > .env.mac-m3 << EOF
# Mac M3 Optimized Environment Variables
# Generated: $(date)

# System Configuration
MAC_M3_MEMORY_GB=${memory_gb}
MAC_M3_CPU_CORES=${cpu_cores}

# PyTorch Optimizations
PYTORCH_ENABLE_MPS_FALLBACK=1
PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
FLASH_ATTENTION_FORCE_FALLBACK=1
TRANSFORMERS_NO_FLASH_ATTENTION=1
DISABLE_FLASH_ATTN=1
ACCELERATE_USE_CPU=1

# CPU Threading (optimized for M3)
OMP_NUM_THREADS=$((cpu_cores > 8 ? 8 : cpu_cores))
MKL_NUM_THREADS=$((cpu_cores > 8 ? 8 : cpu_cores))
VECLIB_MAXIMUM_THREADS=$((cpu_cores > 8 ? 8 : cpu_cores))
NUMEXPR_NUM_THREADS=$((cpu_cores > 8 ? 8 : cpu_cores))
OPENBLAS_NUM_THREADS=$((cpu_cores > 8 ? 8 : cpu_cores))

# Memory Management
MALLOC_ARENA_MAX=4
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# Performance Tuning
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
UV_CACHE_DIR=/root/open-avatar-chat/.cache/uv
PIP_CACHE_DIR=/root/open-avatar-chat/.cache/pip

# Monitoring
ENABLE_MONITORING=${MONITORING_ENABLED}
METRICS_PORT=8283
EOF

    print_success "Created optimized environment configuration"

    # Optimize Docker settings
    print_status "Optimizing Docker daemon settings..."

    # Create or update Docker daemon.json for Mac M3
    local docker_config="$HOME/.docker/daemon.json"
    if [[ -f "$docker_config" ]]; then
        cp "$docker_config" "$docker_config.backup.$(date +%s)"
    fi

    # Suggest Docker settings optimization
    cat << EOF

Recommended Docker Desktop settings for Mac M3 Max:
1. Resources > Memory: Set to $((memory_gb * 3 / 4))GB
2. Resources > CPU: Set to $((cpu_cores > 8 ? cpu_cores - 2 : cpu_cores))
3. Features > Use Docker Compose V2: Enable
4. Features > Use containerd for pulling: Enable
5. Experimental Features: Enable VirtioFS for better performance

To apply these settings:
1. Open Docker Desktop
2. Go to Settings > Resources
3. Adjust Memory and CPU limits as recommended above
4. Click "Apply & Restart"
EOF

    print_success "Mac M3 optimizations applied"
}

# Function to run performance benchmark
run_benchmark() {
    print_header "=== Mac M3 Performance Benchmark ==="

    if [[ "$(check_container_status "$CONTAINER_NAME")" != "running" ]]; then
        print_error "Container is not running. Please start it first."
        return 1
    fi

    print_status "Starting performance benchmark..."

    # CPU benchmark
    print_status "Running CPU benchmark..."
    local cpu_start=$(date +%s.%N)
    docker exec "$CONTAINER_NAME" python3 -c "
import time
import multiprocessing as mp
start = time.time()
# Simple CPU intensive task
for i in range(1000000):
    sum(range(100))
print(f'CPU Benchmark: {time.time() - start:.3f}s')
" 2>/dev/null || echo "CPU benchmark failed"

    # Memory benchmark
    print_status "Running memory benchmark..."
    docker exec "$CONTAINER_NAME" python3 -c "
import time
import sys
start = time.time()
# Memory allocation test
data = []
for i in range(10):
    data.append([0] * 1000000)
    if i % 2 == 0:
        data.clear()
print(f'Memory Benchmark: {time.time() - start:.3f}s')
" 2>/dev/null || echo "Memory benchmark failed"

    # Network benchmark
    print_status "Running network benchmark..."
    local network_start=$(date +%s.%N)
    curl -k -s --max-time 10 -w "Network Latency: %{time_total}s\n" https://localhost:8282/health -o /dev/null || echo "Network benchmark failed"

    # Model inference benchmark (if available)
    print_status "Testing model inference performance..."
    local inference_response=$(curl -k -s --max-time 30 -X POST \
        -H "Content-Type: application/json" \
        -d '{"message": "Hello, this is a performance test."}' \
        https://localhost:8282/api/chat 2>/dev/null || echo "")

    if [[ -n "$inference_response" ]]; then
        print_success "Model inference test completed"
    else
        print_warning "Model inference test failed or timed out"
    fi

    print_success "Benchmark completed"
}

# Function to manage containers
manage_containers() {
    local action=$1

    case $action in
        "start")
            print_status "Starting Mac M3 advanced stack..."
            if [[ -f "$COMPOSE_FILE" ]]; then
                docker-compose -f "$COMPOSE_FILE" up -d
                print_success "Stack started successfully"
                sleep 5
                show_health
            else
                print_error "Compose file not found: $COMPOSE_FILE"
                exit 1
            fi
            ;;
        "stop")
            print_status "Stopping Mac M3 advanced stack..."
            if [[ -f "$COMPOSE_FILE" ]]; then
                docker-compose -f "$COMPOSE_FILE" down
                print_success "Stack stopped successfully"
            else
                print_warning "Compose file not found, stopping individual containers..."
                local containers=("$CONTAINER_NAME" "avatar-redis" "avatar-prometheus" "avatar-grafana" "avatar-nginx")
                for container in "${containers[@]}"; do
                    if [[ "$(check_container_status "$container")" == "running" ]]; then
                        docker stop "$container" && print_success "Stopped $container"
                    fi
                done
            fi
            ;;
        "restart")
            manage_containers "stop"
            sleep 2
            manage_containers "start"
            ;;
        "logs")
            if [[ "$(check_container_status "$CONTAINER_NAME")" == "running" ]]; then
                docker logs -f --tail=50 "$CONTAINER_NAME"
            else
                print_error "Container is not running"
            fi
            ;;
        "shell")
            if [[ "$(check_container_status "$CONTAINER_NAME")" == "running" ]]; then
                docker exec -it "$CONTAINER_NAME" /bin/bash
            else
                print_error "Container is not running"
            fi
            ;;
    esac
}

# Function to cleanup resources
cleanup_resources() {
    print_header "=== Cleanup Resources ==="

    print_status "Stopping all containers..."
    manage_containers "stop"

    print_status "Removing unused containers..."
    docker container prune -f

    print_status "Removing unused images..."
    docker image prune -f

    print_status "Removing unused volumes..."
    docker volume prune -f

    print_status "Removing unused networks..."
    docker network prune -f

    print_status "Cleaning build cache..."
    docker builder prune -f

    print_success "Cleanup completed"
}

# Function to backup configuration
backup_config() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    print_status "Creating backup in $backup_dir..."

    # Backup configuration files
    cp -r config "$backup_dir/"
    cp -r ssl_certs "$backup_dir/" 2>/dev/null || true
    cp "$COMPOSE_FILE" "$backup_dir/" 2>/dev/null || true
    cp .env* "$backup_dir/" 2>/dev/null || true

    # Backup data volumes
    if [[ "$(check_container_status "avatar-redis")" == "running" ]]; then
        docker exec avatar-redis redis-cli BGSAVE
        sleep 2
        cp -r data/redis "$backup_dir/" 2>/dev/null || true
    fi

    # Create backup manifest
    cat > "$backup_dir/manifest.txt" << EOF
Backup created: $(date)
System: $(uname -a)
Docker version: $(docker --version)
Containers backed up:
$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}")
EOF

    print_success "Backup created: $backup_dir"
}

# Function to validate configuration
validate_config() {
    print_header "=== Configuration Validation ==="

    local errors=0

    # Check config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config file not found: $CONFIG_FILE"
        ((errors++))
    else
        print_success "Config file found: $CONFIG_FILE"

        # Validate YAML syntax
        if command -v python3 &> /dev/null; then
            python3 -c "
import yaml
try:
    with open('$CONFIG_FILE', 'r') as f:
        yaml.safe_load(f)
    print('✓ YAML syntax is valid')
except Exception as e:
    print(f'✗ YAML syntax error: {e}')
    exit(1)
" || ((errors++))
        fi
    fi

    # Check required directories
    local required_dirs=("models" "logs" "ssl_certs" "resource")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Directory exists: $dir"
        else
            print_error "Directory missing: $dir"
            ((errors++))
        fi
    done

    # Check SSL certificates
    if [[ -f "ssl_certs/localhost.crt" && -f "ssl_certs/localhost.key" ]]; then
        print_success "SSL certificates found"

        # Check certificate validity
        if openssl x509 -in ssl_certs/localhost.crt -checkend 86400 &> /dev/null; then
            print_success "SSL certificate is valid"
        else
            print_warning "SSL certificate is expired or will expire within 24 hours"
        fi
    else
        print_warning "SSL certificates not found"
    fi

    # Check Docker compose file
    if [[ -f "$COMPOSE_FILE" ]]; then
        print_success "Compose file found: $COMPOSE_FILE"

        if command -v docker-compose &> /dev/null; then
            if docker-compose -f "$COMPOSE_FILE" config &> /dev/null; then
                print_success "Compose file syntax is valid"
            else
                print_error "Compose file syntax is invalid"
                ((errors++))
            fi
        fi
    else
        print_warning "Compose file not found: $COMPOSE_FILE"
    fi

    if [[ $errors -eq 0 ]]; then
        print_success "All validations passed"
    else
        print_error "Found $errors validation error(s)"
        return 1
    fi
}

# Function to show real-time monitoring
show_monitoring() {
    print_header "=== Real-time Mac M3 Monitoring ==="
    print_status "Press Ctrl+C to exit monitoring mode"
    echo ""

    while true; do
        clear
        echo -e "${BOLD}Mac M3 OpenAvatarChat Monitoring Dashboard${NC}"
        echo -e "${BOLD}$(date)${NC}"
        echo ""

        # System information
        get_system_info
        echo ""

        # Container status
        show_health
        echo ""

        # Performance metrics
        show_metrics

        sleep 10
    done
}

# Initialize logging
mkdir -p logs
touch "$LOG_FILE"

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|status|logs|shell|build|rebuild|deploy|update|monitor|health|debug|profile|metrics|cleanup|backup|restore|reset|config|validate|optimize|tune|requirements|benchmark|thermal|memory)
            COMMAND="$1"
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --monitoring)
            MONITORING_ENABLED=true
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --compose)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
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

# Check prerequisites
check_prerequisites

# Main command execution
case $COMMAND in
    "start")
        manage_containers "start"
        if [[ "$MONITORING_ENABLED" == "true" ]]; then
            sleep 5
            show_monitoring
        fi
        ;;
    "stop")
        manage_containers "stop"
        ;;
    "restart")
        manage_containers "restart"
        ;;
    "status")
        show_health
        ;;
    "logs")
        manage_containers "logs"
        ;;
    "shell")
        manage_containers "shell"
        ;;
    "build")
        print_status "Building Mac M3 advanced image..."
        ./build_mac_m3_advanced.sh --no-run
        ;;
    "rebuild")
        print_status "Rebuilding Mac M3 advanced image..."
        ./build_mac_m3_advanced.sh --clean --no-cache --no-run
        ;;
    "deploy")
        print_status "Deploying Mac M3 advanced stack..."
        validate_config
        manage_containers "start"
        ;;
    "monitor")
        show_monitoring
        ;;
    "health")
        show_health
        ;;
    "metrics")
        show_metrics
        ;;
    "optimize")
        optimize_system
        ;;
    "benchmark")
        run_benchmark
        ;;
    "cleanup")
        cleanup_resources
        ;;
    "backup")
        backup_config
        ;;
    "validate")
        validate_config
        ;;
    "config")
        print_header "=== Current Configuration ==="
        get_system_info
        echo ""
        echo "Configuration File: $CONFIG_FILE"
        echo "Compose File: $COMPOSE_FILE"
        echo "Container Name: $CONTAINER_NAME"
        echo "Image Name: $IMAGE_NAME"
        echo "Monitoring Enabled: $MONITORING_ENABLED"
        echo "Verbose Mode: $VERBOSE"
        ;;
    "requirements")
        print_header "=== System Requirements Check ==="
        get_system_info
        echo ""
        validate_config
        ;;
    *)
        if [[ -z "$COMMAND" ]]; then
            print_error "No command specified"
        else
            print_error "Unknown command: $COMMAND"
        fi
        echo ""
        show_usage
        exit 1
        ;;
esac
