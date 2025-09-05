#!/bin/bash

# OpenAvatarChat Docker Compose Management Script
# Easily manage OpenAI and Ollama versions of OpenAvatarChat

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to show usage
show_usage() {
    print_header "OpenAvatarChat Management Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup-openai      Set up OpenAI version (requires API key)"
    echo "  setup-ollama      Set up Ollama version (local AI)"
    echo "  start-openai      Start OpenAI version"
    echo "  start-ollama      Start Ollama version"
    echo "  stop-openai       Stop OpenAI version"
    echo "  stop-ollama       Stop Ollama version"
    echo "  restart-openai    Restart OpenAI version"
    echo "  restart-ollama    Restart Ollama version"
    echo "  status            Show status of all services"
    echo "  logs-openai       Show OpenAI logs"
    echo "  logs-ollama       Show Ollama logs"
    echo "  logs-ollama-server Show Ollama server logs"
    echo "  clean             Clean up containers and volumes"
    echo "  build             Build/rebuild images"
    echo "  test-openai       Test OpenAI version"
    echo "  test-ollama       Test Ollama version"
    echo "  models            Manage Ollama models"
    echo "  backup            Backup Ollama models"
    echo "  restore           Restore Ollama models"
    echo ""
    echo "Options:"
    echo "  --help, -h        Show this help message"
    echo "  --verbose, -v     Verbose output"
    echo "  --force, -f       Force operation (skip confirmations)"
    echo ""
    echo "Examples:"
    echo "  $0 setup-ollama           # Set up local AI with Ollama"
    echo "  $0 start-openai           # Start OpenAI version"
    echo "  $0 status                 # Show all service status"
    echo "  $0 logs-ollama --follow   # Follow Ollama logs"
    echo ""
    echo "Web Interfaces:"
    echo "  OpenAI version:  https://localhost:8282"
    echo "  Ollama version:  https://localhost:8283"
    echo "  Ollama API:      http://localhost:11434"
}

# Parse command line arguments
COMMAND=""
VERBOSE=false
FORCE=false
FOLLOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --follow)
            FOLLOW_LOGS=true
            shift
            ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            fi
            shift
            ;;
    esac
done

# Check if Docker and Docker Compose are available
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available"
        exit 1
    fi
}

# Check if .env file exists for OpenAI
check_openai_env() {
    if [[ ! -f ".env" ]]; then
        print_warning "No .env file found. Creating template..."
        cat > .env << 'EOF'
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Mac M3 Optimizations
PYTORCH_ENABLE_MPS_FALLBACK=1
PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
OMP_NUM_THREADS=8
MKL_NUM_THREADS=8
VECLIB_MAXIMUM_THREADS=8
NUMEXPR_NUM_THREADS=8

# Optional: Logging
LOG_LEVEL=INFO

# Optional: Model Cache Directories
TRANSFORMERS_CACHE=/root/open-avatar-chat/models/transformers_cache
HF_HOME=/root/open-avatar-chat/models/huggingface_cache
EOF
        print_warning "Please edit .env file and add your OpenAI API key"
        return 1
    fi

    source .env
    if [[ -z "$OPENAI_API_KEY" || "$OPENAI_API_KEY" == "your_openai_api_key_here" ]]; then
        print_error "Please set your OpenAI API key in .env file"
        return 1
    fi

    return 0
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p models logs ssl_certs resource
    print_success "Directories created"
}

# Generate SSL certificates
generate_ssl_certs() {
    if [[ ! -f "ssl_certs/localhost.crt" || ! -f "ssl_certs/localhost.key" ]]; then
        print_status "Generating SSL certificates..."
        openssl req -x509 -newkey rsa:4096 -keyout ssl_certs/localhost.key \
            -out ssl_certs/localhost.crt -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
            2>/dev/null || {
            print_warning "Failed to generate SSL certificates. HTTPS may not work."
        }
    fi
}

# Setup OpenAI version
setup_openai() {
    print_header "Setting up OpenAI Version"

    if ! check_openai_env; then
        return 1
    fi

    create_directories
    generate_ssl_certs

    print_status "Building OpenAI version..."
    docker compose --profile openai build

    print_success "OpenAI version setup complete"
    print_status "Start with: $0 start-openai"
}

# Setup Ollama version
setup_ollama() {
    print_header "Setting up Ollama Version"

    create_directories
    generate_ssl_certs

    print_status "Building Ollama version..."
    docker compose --profile ollama build

    print_success "Ollama version setup complete"
    print_status "Start with: $0 start-ollama"
}

# Start OpenAI version
start_openai() {
    print_header "Starting OpenAI Version"

    if ! check_openai_env; then
        return 1
    fi

    print_status "Starting OpenAI services..."
    docker compose --profile openai up -d

    print_success "OpenAI version started"
    print_status "Web interface: https://localhost:8282"
    print_status "View logs: $0 logs-openai"
}

# Start Ollama version
start_ollama() {
    print_header "Starting Ollama Version"

    print_status "Starting Ollama services..."
    docker compose --profile ollama up -d

    print_success "Ollama version started"
    print_status "Web interface: https://localhost:8283"
    print_status "Ollama API: http://localhost:11434"
    print_status "View logs: $0 logs-ollama"

    print_status "Waiting for Ollama to download models (this may take several minutes)..."
    print_status "Monitor progress: $0 logs-ollama-server --follow"
}

# Stop services
stop_openai() {
    print_status "Stopping OpenAI services..."
    docker compose --profile openai down
    print_success "OpenAI services stopped"
}

stop_ollama() {
    print_status "Stopping Ollama services..."
    docker compose --profile ollama down
    print_success "Ollama services stopped"
}

# Restart services
restart_openai() {
    print_status "Restarting OpenAI services..."
    docker compose --profile openai restart
    print_success "OpenAI services restarted"
}

restart_ollama() {
    print_status "Restarting Ollama services..."
    docker compose --profile ollama restart
    print_success "Ollama services restarted"
}

# Show status
show_status() {
    print_header "Service Status"
    echo ""

    # Check OpenAI services
    echo -e "${CYAN}OpenAI Services:${NC}"
    if docker compose --profile openai ps --services | grep -q .; then
        docker compose --profile openai ps
    else
        echo "  No OpenAI services running"
    fi
    echo ""

    # Check Ollama services
    echo -e "${CYAN}Ollama Services:${NC}"
    if docker compose --profile ollama ps --services | grep -q .; then
        docker compose --profile ollama ps
    else
        echo "  No Ollama services running"
    fi
    echo ""

    # Check web interfaces
    echo -e "${CYAN}Web Interface Status:${NC}"
    if curl -k -s --connect-timeout 3 https://localhost:8282/ >/dev/null 2>&1; then
        print_success "OpenAI interface: https://localhost:8282 (accessible)"
    else
        echo "  OpenAI interface: https://localhost:8282 (not accessible)"
    fi

    if curl -k -s --connect-timeout 3 https://localhost:8283/ >/dev/null 2>&1; then
        print_success "Ollama interface: https://localhost:8283 (accessible)"
    else
        echo "  Ollama interface: https://localhost:8283 (not accessible)"
    fi

    if curl -s --connect-timeout 3 http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_success "Ollama API: http://localhost:11434 (accessible)"

        # Show available models
        MODELS=$(curl -s http://localhost:11434/api/tags 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    models = [model['name'] for model in data.get('models', [])]
    print('Available models: ' + ', '.join(models) if models else 'No models installed')
except:
    print('Error reading models')
" 2>/dev/null || echo "Error checking models")
        echo "  $MODELS"
    else
        echo "  Ollama API: http://localhost:11434 (not accessible)"
    fi
}

# Show logs
show_logs() {
    local service="$1"
    local follow_flag=""

    if [[ "$FOLLOW_LOGS" == "true" ]]; then
        follow_flag="-f"
    fi

    case $service in
        openai)
            docker compose --profile openai logs $follow_flag open-avatar-chat-openai
            ;;
        ollama)
            docker compose --profile ollama logs $follow_flag open-avatar-chat-ollama
            ;;
        ollama-server)
            docker compose --profile ollama logs $follow_flag ollama
            ;;
    esac
}

# Test services
test_openai() {
    print_header "Testing OpenAI Version"

    if ! curl -k -s --connect-timeout 5 https://localhost:8282/ >/dev/null; then
        print_error "OpenAI service not accessible"
        return 1
    fi

    print_success "OpenAI service is accessible"
    print_status "Try sending a message at: https://localhost:8282"
}

test_ollama() {
    print_header "Testing Ollama Version"

    # Test Ollama API
    if ! curl -s --connect-timeout 5 http://localhost:11434/api/tags >/dev/null; then
        print_error "Ollama API not accessible"
        return 1
    fi

    print_success "Ollama API is accessible"

    # Test web interface
    if ! curl -k -s --connect-timeout 5 https://localhost:8283/ >/dev/null; then
        print_error "Ollama web interface not accessible"
        return 1
    fi

    print_success "Ollama web interface is accessible"
    print_status "Try sending a message at: https://localhost:8283"
}

# Manage Ollama models
manage_models() {
    print_header "Ollama Model Management"

    if ! docker compose --profile ollama ps | grep -q ollama; then
        print_error "Ollama service is not running. Start with: $0 start-ollama"
        return 1
    fi

    echo "Available commands:"
    echo "  list    - List installed models"
    echo "  pull    - Pull a new model"
    echo "  remove  - Remove a model"
    echo "  info    - Show model information"
    echo ""

    read -p "Enter command: " cmd

    case $cmd in
        list)
            docker compose exec ollama ollama list
            ;;
        pull)
            read -p "Enter model name (e.g., qwen2.5vl, llama3:8b): " model_name
            docker compose exec ollama ollama pull "$model_name"
            ;;
        remove)
            docker compose exec ollama ollama list
            read -p "Enter model name to remove: " model_name
            docker compose exec ollama ollama rm "$model_name"
            ;;
        info)
            read -p "Enter model name: " model_name
            docker compose exec ollama ollama show "$model_name"
            ;;
        *)
            print_error "Unknown command: $cmd"
            ;;
    esac
}

# Clean up
clean_all() {
    print_header "Cleaning Up"

    if [[ "$FORCE" != "true" ]]; then
        read -p "This will remove all containers and volumes. Continue? (y/N): " confirm
        if [[ $confirm != [yY] ]]; then
            print_status "Cancelled"
            return 0
        fi
    fi

    print_status "Stopping all services..."
    docker compose --profile openai --profile ollama down -v

    print_status "Removing unused images..."
    docker image prune -f

    print_success "Cleanup complete"
}

# Build images
build_all() {
    print_header "Building Images"

    print_status "Building OpenAI version..."
    docker compose --profile openai build

    print_status "Building Ollama version..."
    docker compose --profile ollama build

    print_success "All images built successfully"
}

# Backup Ollama models
backup_models() {
    print_header "Backing up Ollama Models"

    BACKUP_DIR="./backups/ollama_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    print_status "Creating backup in $BACKUP_DIR..."
    docker run --rm -v ollama_data:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine \
        tar czf /backup/ollama_models.tar.gz -C /source .

    print_success "Backup created: $BACKUP_DIR/ollama_models.tar.gz"
}

# Restore Ollama models
restore_models() {
    print_header "Restoring Ollama Models"

    echo "Available backups:"
    ls -la backups/*/ollama_models.tar.gz 2>/dev/null || {
        print_error "No backups found"
        return 1
    }

    read -p "Enter backup path: " backup_path

    if [[ ! -f "$backup_path" ]]; then
        print_error "Backup file not found: $backup_path"
        return 1
    fi

    print_status "Restoring from $backup_path..."
    docker run --rm -v ollama_data:/target -v "$(pwd)/$backup_path":/backup/ollama_models.tar.gz alpine \
        tar xzf /backup/ollama_models.tar.gz -C /target

    print_success "Models restored successfully"
    print_status "Restart Ollama to use restored models: $0 restart-ollama"
}

# Main command dispatcher
main() {
    if [[ -z "$COMMAND" ]]; then
        show_usage
        exit 1
    fi

    check_dependencies

    case $COMMAND in
        setup-openai)
            setup_openai
            ;;
        setup-ollama)
            setup_ollama
            ;;
        start-openai)
            start_openai
            ;;
        start-ollama)
            start_ollama
            ;;
        stop-openai)
            stop_openai
            ;;
        stop-ollama)
            stop_ollama
            ;;
        restart-openai)
            restart_openai
            ;;
        restart-ollama)
            restart_ollama
            ;;
        status)
            show_status
            ;;
        logs-openai)
            show_logs "openai"
            ;;
        logs-ollama)
            show_logs "ollama"
            ;;
        logs-ollama-server)
            show_logs "ollama-server"
            ;;
        test-openai)
            test_openai
            ;;
        test-ollama)
            test_ollama
            ;;
        models)
            manage_models
            ;;
        clean)
            clean_all
            ;;
        build)
            build_all
            ;;
        backup)
            backup_models
            ;;
        restore)
            restore_models
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
