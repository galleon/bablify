#!/bin/bash

# Build and Run Script for Mac M3 Max
# OpenAvatarChat Mac M3 Optimized Version

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
BUILD_TYPE="development"
CLEAN_BUILD=false
RUN_AFTER_BUILD=true
USE_CACHE=true
CONFIG_FILE="config/chat_with_minicpm_mac_m3.yaml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --build-type TYPE     Build type: development|production (default: development)"
    echo "  --clean              Clean build (remove existing images and containers)"
    echo "  --no-run             Don't run the container after building"
    echo "  --no-cache           Don't use Docker cache"
    echo "  --config FILE        Config file to use (default: $CONFIG_FILE)"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Development build and run"
    echo "  $0 --build-type production --clean   # Production build with clean"
    echo "  $0 --no-run --no-cache              # Build only without cache"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --no-run)
            RUN_AFTER_BUILD=false
            shift
            ;;
        --no-cache)
            USE_CACHE=false
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
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

# Validate build type
if [[ "$BUILD_TYPE" != "development" && "$BUILD_TYPE" != "production" ]]; then
    print_error "Invalid build type: $BUILD_TYPE. Must be 'development' or 'production'"
    exit 1
fi

print_status "Starting Mac M3 Max optimized build..."
print_status "Build Type: $BUILD_TYPE"
print_status "Config File: $CONFIG_FILE"

# Initialize git submodules if needed
print_status "Checking git submodules..."
if git submodule status | grep -q '^-'; then
    print_status "Initializing git submodules (required for fastrtc and other dependencies)..."
    if git submodule update --init --recursive; then
        print_success "Git submodules initialized successfully"
    else
        print_error "Failed to initialize git submodules"
        print_status "Please run: git submodule update --init --recursive"
        exit 1
    fi
else
    print_status "Git submodules already initialized"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Config file not found: $CONFIG_FILE"
    print_status "Available config files:"
    ls -la config/ | grep -E "\.yaml$|\.yml$" || echo "No config files found"
    exit 1
fi

# System requirements check
print_status "Checking system requirements..."

# Check available memory
AVAILABLE_MEMORY=$(sysctl hw.memsize | awk '{print $2/1024/1024/1024}')
if (( $(echo "$AVAILABLE_MEMORY < 16" | bc -l) )); then
    print_warning "Available memory: ${AVAILABLE_MEMORY}GB. Recommended: 16GB or more for optimal performance."
fi

# Check CPU architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    print_warning "Architecture: $ARCH. This script is optimized for Apple Silicon (arm64)."
fi

# Clean existing containers and images if requested
if [[ "$CLEAN_BUILD" == "true" ]]; then
    print_status "Cleaning existing containers and images..."

    # Stop and remove existing containers
    docker stop open-avatar-chat-mac-m3 2>/dev/null || true
    docker rm open-avatar-chat-mac-m3 2>/dev/null || true

    # Remove existing images
    docker rmi open-avatar-chat:mac-m3 2>/dev/null || true
    docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || true

    print_success "Cleanup completed"
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p models
mkdir -p logs
mkdir -p ssl_certs
mkdir -p resource

# Generate SSL certificates if they don't exist
if [[ ! -f "ssl_certs/localhost.crt" || ! -f "ssl_certs/localhost.key" ]]; then
    print_status "Generating SSL certificates..."
    openssl req -x509 -newkey rsa:4096 -keyout ssl_certs/localhost.key \
        -out ssl_certs/localhost.crt -days 365 -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" 2>/dev/null || {
        print_warning "Failed to generate SSL certificates. HTTPS may not work."
    }
fi

# Build Docker image
print_status "Building Docker image for Mac M3..."

BUILD_ARGS="--build-arg CONFIG_FILE=$CONFIG_FILE"
BUILD_ARGS="$BUILD_ARGS --platform linux/arm64"

if [[ "$USE_CACHE" == "false" ]]; then
    BUILD_ARGS="$BUILD_ARGS --no-cache"
fi

if [[ "$BUILD_TYPE" == "production" ]]; then
    BUILD_ARGS="$BUILD_ARGS --target production"
fi

print_status "Build command: docker build -f Dockerfile.mac-m3 $BUILD_ARGS -t open-avatar-chat:mac-m3 ."

if docker build -f Dockerfile.mac-m3 $BUILD_ARGS -t open-avatar-chat:mac-m3 .; then
    print_success "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Run the container if requested
if [[ "$RUN_AFTER_BUILD" == "true" ]]; then
    print_status "Starting container..."

    # Stop existing container if running
    docker stop open-avatar-chat-mac-m3 2>/dev/null || true
    docker rm open-avatar-chat-mac-m3 2>/dev/null || true

    # Run the container with Mac M3 optimizations
    docker run -d \
        --name open-avatar-chat-mac-m3 \
        --platform linux/arm64 \
        -p 8282:8282 \
        -v "$(pwd)/models:/root/open-avatar-chat/models" \
        -v "$(pwd)/resource:/root/open-avatar-chat/resource" \
        -v "$(pwd)/ssl_certs:/root/open-avatar-chat/ssl_certs" \
        -v "$(pwd)/logs:/root/open-avatar-chat/logs" \
        -e PYTORCH_ENABLE_MPS_FALLBACK=1 \
        -e PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 \
        -e OMP_NUM_THREADS=8 \
        -e MKL_NUM_THREADS=8 \
        -e VECLIB_MAXIMUM_THREADS=8 \
        -e NUMEXPR_NUM_THREADS=8 \
        -e ACCELERATE_USE_CPU=1 \
        --memory=16g \
        --cpus=8.0 \
        --restart unless-stopped \
        open-avatar-chat:mac-m3

    if [[ $? -eq 0 ]]; then
        print_success "Container started successfully"
        print_status "Container name: open-avatar-chat-mac-m3"
        print_status "Web interface: https://localhost:8282"
        print_status ""
        print_status "Useful commands:"
        print_status "  View logs:    docker logs -f open-avatar-chat-mac-m3"
        print_status "  Stop:         docker stop open-avatar-chat-mac-m3"
        print_status "  Restart:      docker restart open-avatar-chat-mac-m3"
        print_status "  Enter shell:  docker exec -it open-avatar-chat-mac-m3 /bin/bash"

        # Wait for container to be ready
        print_status "Waiting for service to be ready..."
        for i in {1..30}; do
            if curl -k -s https://localhost:8282/health > /dev/null 2>&1; then
                print_success "Service is ready! Access it at https://localhost:8282"
                break
            elif [[ $i -eq 30 ]]; then
                print_warning "Service might still be starting up. Check logs with: docker logs -f open-avatar-chat-mac-m3"
            else
                echo -n "."
                sleep 2
            fi
        done
        echo ""

    else
        print_error "Failed to start container"
        exit 1
    fi
else
    print_success "Build completed. Image tagged as: open-avatar-chat:mac-m3"
    print_status "To run the container manually:"
    print_status "  docker run -d --name open-avatar-chat-mac-m3 -p 8282:8282 open-avatar-chat:mac-m3"
fi

print_success "Mac M3 build process completed!"
