#!/bin/bash

# Simple Mac M3 Build Script - Tested and Working
# Based on existing build_mac_m3.sh with optimizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKERFILE="Dockerfile.mac-m3-optimized"
IMAGE_NAME="open-avatar-chat"
IMAGE_TAG="mac-m3-optimized"
CONTAINER_NAME="open-avatar-chat-mac-m3-optimized"
CONFIG_FILE="config/chat_with_minicpm_mac_m3.yaml"
CLEAN_BUILD=false
RUN_AFTER_BUILD=true
USE_CACHE=true

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

# Function to show usage
show_usage() {
    echo "Simple Mac M3 Build Script - Optimized Version"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --clean              Clean build (remove existing images and containers)"
    echo "  --no-run             Don't run the container after building"
    echo "  --no-cache           Don't use Docker cache"
    echo "  --config FILE        Config file to use (default: $CONFIG_FILE)"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Standard optimized build"
    echo "  $0 --clean           # Clean build from scratch"
    echo "  $0 --no-run          # Build only, don't run"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

print_status "Starting Mac M3 Optimized Build..."

# Check prerequisites
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Config file not found: $CONFIG_FILE"
    print_status "Available config files:"
    find config/ -name "*.yaml" -o -name "*.yml" 2>/dev/null || echo "No config files found"
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p models logs ssl_certs resource

# Generate SSL certificates if they don't exist
if [[ ! -f "ssl_certs/localhost.crt" || ! -f "ssl_certs/localhost.key" ]]; then
    print_status "Generating SSL certificates..."
    openssl req -x509 -newkey rsa:4096 -keyout ssl_certs/localhost.key \
        -out ssl_certs/localhost.crt -days 365 -nodes \
        -subj "/C=US/ST=CA/L=City/O=OpenAvatarChat/CN=localhost" 2>/dev/null || {
        print_warning "Failed to generate SSL certificates. HTTPS may not work."
    }
fi

# Clean existing containers and images if requested
if [[ "$CLEAN_BUILD" == "true" ]]; then
    print_status "Cleaning existing containers and images..."

    # Stop and remove existing containers
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    # Remove existing images
    docker rmi "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null || true

    print_success "Cleanup completed"
fi

# Build Docker image
print_status "Building optimized Docker image..."

BUILD_ARGS="--build-arg CONFIG_FILE=$CONFIG_FILE"
BUILD_ARGS="$BUILD_ARGS --platform linux/arm64"
BUILD_ARGS="$BUILD_ARGS -f $DOCKERFILE"

if [[ "$USE_CACHE" == "false" ]]; then
    BUILD_ARGS="$BUILD_ARGS --no-cache"
fi

BUILD_ARGS="$BUILD_ARGS -t ${IMAGE_NAME}:${IMAGE_TAG} ."

print_status "Build command: docker build $BUILD_ARGS"

BUILD_START_TIME=$(date +%s)

if docker build $BUILD_ARGS; then
    BUILD_END_TIME=$(date +%s)
    BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))
    print_success "Docker image built successfully in ${BUILD_DURATION} seconds"

    # Show image size
    IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Size}}" | tail -n +2)
    print_status "Image size: $IMAGE_SIZE"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Run the container if requested
if [[ "$RUN_AFTER_BUILD" == "true" ]]; then
    print_status "Starting optimized container..."

    # Stop existing container if running
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    # Get system info for optimization
    AVAILABLE_MEMORY=$(sysctl hw.memsize 2>/dev/null | awk '{print int($2/1024/1024/1024)}' || echo "16")
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "8")

    # Set resource limits based on available hardware
    if (( AVAILABLE_MEMORY >= 32 )); then
        MEMORY_LIMIT="24g"
        CPU_LIMIT="10.0"
    elif (( AVAILABLE_MEMORY >= 16 )); then
        MEMORY_LIMIT="12g"
        CPU_LIMIT="8.0"
    else
        MEMORY_LIMIT="8g"
        CPU_LIMIT="4.0"
    fi

    print_status "Using limits: Memory=$MEMORY_LIMIT, CPU=$CPU_LIMIT (detected: ${AVAILABLE_MEMORY}GB, ${CPU_CORES} cores)"

    # Run container with optimizations
    docker run -d \
        --name "$CONTAINER_NAME" \
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
        --memory="$MEMORY_LIMIT" \
        --cpus="$CPU_LIMIT" \
        --restart unless-stopped \
        "${IMAGE_NAME}:${IMAGE_TAG}"

    if [[ $? -eq 0 ]]; then
        print_success "Container started successfully"
        print_status "Container name: $CONTAINER_NAME"
        print_status "Resource limits: Memory=$MEMORY_LIMIT, CPU=$CPU_LIMIT"
        print_status ""
        print_status "🌐 Access URLs:"
        print_status "  Web interface: https://localhost:8282"
        print_status "  Health check:  http://localhost:8282/health"
        print_status ""
        print_status "📋 Management Commands:"
        print_status "  View logs:     docker logs -f $CONTAINER_NAME"
        print_status "  Stop:          docker stop $CONTAINER_NAME"
        print_status "  Restart:       docker restart $CONTAINER_NAME"
        print_status "  Enter shell:   docker exec -it $CONTAINER_NAME /bin/bash"
        print_status "  Remove:        docker rm -f $CONTAINER_NAME"

        # Wait for container to be ready
        print_status "⏳ Waiting for service to be ready..."
        for i in {1..30}; do
            if curl -k -s --max-time 5 --connect-timeout 2 https://localhost:8282/health > /dev/null 2>&1; then
                print_success "🎉 Service is ready! Access it at https://localhost:8282"
                break
            elif [[ $i -eq 30 ]]; then
                print_warning "Service might still be starting up. Check logs with: docker logs -f $CONTAINER_NAME"
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
    print_success "Build completed successfully!"
    print_status "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    print_status "To run manually:"
    print_status "  docker run -d --name $CONTAINER_NAME -p 8282:8282 ${IMAGE_NAME}:${IMAGE_TAG}"
fi

print_success "Mac M3 optimized build process completed!"

# Show final status
print_status ""
print_status "📊 Build Summary:"
print_status "  Dockerfile: $DOCKERFILE"
print_status "  Image: ${IMAGE_NAME}:${IMAGE_TAG}"
print_status "  Config: $CONFIG_FILE"
print_status "  Build time: ${BUILD_DURATION:-0} seconds"
print_status "  Image size: ${IMAGE_SIZE:-unknown}"

if [[ "$RUN_AFTER_BUILD" == "true" ]]; then
    print_status "  Container: $CONTAINER_NAME (running)"
    print_status "  Memory limit: $MEMORY_LIMIT"
    print_status "  CPU limit: $CPU_LIMIT"
fi
