#!/bin/bash

# Advanced Build Script for Mac M3 Max - OpenAvatarChat
# Multi-stage Docker build with advanced optimization features
# Version 2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_progress() {
    echo -e "${PURPLE}[PROGRESS]${NC} $1"
}

print_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Default values
BUILD_TYPE="development"
DOCKERFILE="Dockerfile.mac-m3-advanced"
IMAGE_NAME="open-avatar-chat"
IMAGE_TAG="mac-m3-advanced"
CONTAINER_NAME="open-avatar-chat-mac-m3-advanced"
CLEAN_BUILD=false
RUN_AFTER_BUILD=true
USE_CACHE=true
PARALLEL_BUILD=true
CONFIG_FILE="config/chat_with_minicpm_mac_m3.yaml"
DEBUG_MODE=false
PUSH_TO_REGISTRY=false
REGISTRY_URL=""
BUILD_ARGS=""
MEMORY_LIMIT="16g"
CPU_LIMIT="8.0"
HEALTH_CHECK_TIMEOUT=120
ENABLE_MONITORING=false

# Performance optimization flags
BUILDKIT_ENABLED=true
EXPERIMENTAL_FEATURES=false
MULTI_PLATFORM=false

# Function to show usage
show_usage() {
    cat << EOF
Advanced Mac M3 Build Script for OpenAvatarChat v2.0

USAGE:
    $0 [OPTIONS]

OPTIONS:
    Build Configuration:
    --build-type TYPE        Build type: development|production|testing (default: development)
    --dockerfile FILE        Dockerfile to use (default: $DOCKERFILE)
    --config FILE           Config file to use (default: $CONFIG_FILE)
    --image-name NAME       Docker image name (default: $IMAGE_NAME)
    --image-tag TAG         Docker image tag (default: $IMAGE_TAG)

    Build Options:
    --clean                 Clean build (remove existing images and containers)
    --no-cache              Don't use Docker cache
    --no-parallel           Disable parallel build operations
    --experimental          Enable Docker experimental features
    --multi-platform        Build for multiple platforms (linux/arm64,linux/amd64)

    Runtime Options:
    --no-run               Don't run the container after building
    --memory LIMIT         Memory limit for container (default: $MEMORY_LIMIT)
    --cpu LIMIT            CPU limit for container (default: $CPU_LIMIT)
    --enable-monitoring    Enable container monitoring and metrics

    Registry Options:
    --push                 Push image to registry after build
    --registry URL         Registry URL for pushing images

    Development Options:
    --debug                Enable debug mode with verbose output
    --build-args ARGS      Additional build arguments

    Other Options:
    --help                 Show this help message

EXAMPLES:
    # Standard development build
    $0

    # Production build with cleanup
    $0 --build-type production --clean

    # Debug build without running
    $0 --debug --no-run --no-cache

    # Multi-platform build and push to registry
    $0 --multi-platform --push --registry myregistry.com

    # Custom configuration with monitoring
    $0 --config config/my_config.yaml --enable-monitoring

    # Testing build with experimental features
    $0 --build-type testing --experimental --debug

ENVIRONMENT VARIABLES:
    DOCKER_BUILDKIT=1       Enable BuildKit (recommended)
    BUILD_PARALLEL_JOBS     Number of parallel build jobs
    MAC_M3_MEMORY_GB        Available memory in GB for optimization
    MAC_M3_CPU_CORES        Number of CPU cores for optimization

EOF
}

# Function to check system requirements
check_system_requirements() {
    print_status "Checking system requirements..."

    # Check macOS version
    if [[ "$(uname)" != "Darwin" ]]; then
        print_warning "This script is optimized for macOS. Current OS: $(uname)"
    fi

    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "arm64" ]]; then
        print_warning "Architecture: $ARCH. This script is optimized for Apple Silicon (arm64)"
    else
        print_success "Apple Silicon detected: $ARCH"
    fi

    # Check available memory
    AVAILABLE_MEMORY=$(sysctl hw.memsize 2>/dev/null | awk '{print int($2/1024/1024/1024)}' || echo "0")
    if (( AVAILABLE_MEMORY < 16 )); then
        print_warning "Available memory: ${AVAILABLE_MEMORY}GB. Recommended: 16GB+ for optimal performance"
        MEMORY_LIMIT="8g"
        CPU_LIMIT="4.0"
    else
        print_success "Available memory: ${AVAILABLE_MEMORY}GB"
        # Optimize limits based on available memory
        if (( AVAILABLE_MEMORY >= 32 )); then
            MEMORY_LIMIT="24g"
            CPU_LIMIT="12.0"
        elif (( AVAILABLE_MEMORY >= 24 )); then
            MEMORY_LIMIT="20g"
            CPU_LIMIT="10.0"
        fi
    fi

    # Check disk space
    AVAILABLE_SPACE=$(df -h . | tail -1 | awk '{print $4}' | sed 's/G.*//')
    if (( ${AVAILABLE_SPACE%.*} < 20 )); then
        print_warning "Available disk space: ${AVAILABLE_SPACE}GB. Recommended: 20GB+ for models and cache"
    else
        print_success "Available disk space: ${AVAILABLE_SPACE}GB"
    fi

    # Check CPU cores
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "8")
    print_success "CPU cores: $CPU_CORES"

    # Optimize CPU limit based on available cores
    if (( CPU_CORES >= 12 )); then
        CPU_LIMIT="${CPU_LIMIT}"  # Keep current value
    elif (( CPU_CORES >= 8 )); then
        CPU_LIMIT="8.0"
    else
        CPU_LIMIT="4.0"
    fi
}

# Function to check Docker requirements
check_docker_requirements() {
    print_status "Checking Docker requirements..."

    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi

    # Check Docker version
    DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_success "Docker version: $DOCKER_VERSION"

    # Check BuildKit support
    if [[ "$BUILDKIT_ENABLED" == "true" ]]; then
        export DOCKER_BUILDKIT=1
        print_success "BuildKit enabled for faster builds"
    fi

    # Check for Docker Compose
    if command -v docker-compose > /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_success "Docker Compose version: $COMPOSE_VERSION"
    fi
}

# Function to initialize project
initialize_project() {
    print_status "Initializing project..."

    # Check if we're in the right directory
    if [[ ! -f "pyproject.mac-m3.toml" ]] || [[ ! -f "$DOCKERFILE" ]]; then
        print_error "Required files not found. Please run from project root directory."
        exit 1
    fi

    # Initialize git submodules if needed
    if git submodule status 2>/dev/null | grep -q '^-'; then
        print_status "Initializing git submodules..."
        if git submodule update --init --recursive --progress; then
            print_success "Git submodules initialized"
        else
            print_error "Failed to initialize git submodules"
            exit 1
        fi
    fi

    # Create necessary directories
    print_status "Creating necessary directories..."
    mkdir -p models logs ssl_certs resource temp
    print_success "Directories created"

    # Generate SSL certificates if needed
    if [[ ! -f "ssl_certs/localhost.crt" ]] || [[ ! -f "ssl_certs/localhost.key" ]]; then
        print_status "Generating SSL certificates..."
        if openssl req -x509 -newkey rsa:4096 -keyout ssl_certs/localhost.key \
            -out ssl_certs/localhost.crt -days 365 -nodes \
            -subj "/C=US/ST=CA/L=SanFrancisco/O=OpenAvatarChat/CN=localhost" 2>/dev/null; then
            print_success "SSL certificates generated"
        else
            print_warning "Failed to generate SSL certificates. HTTPS may not work."
        fi
    fi

    # Validate config file
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config file not found: $CONFIG_FILE"
        print_status "Available config files:"
        find config/ -name "*.yaml" -o -name "*.yml" 2>/dev/null || echo "No config files found"
        exit 1
    fi
    print_success "Config file validated: $CONFIG_FILE"
}

# Function to clean previous builds
clean_previous_builds() {
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        print_status "Cleaning previous builds..."

        # Stop and remove containers
        if docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_status "Stopping and removing existing container: $CONTAINER_NAME"
            docker stop "$CONTAINER_NAME" 2>/dev/null || true
            docker rm "$CONTAINER_NAME" 2>/dev/null || true
        fi

        # Remove images
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "${IMAGE_NAME}:${IMAGE_TAG}"; then
            print_status "Removing existing image: ${IMAGE_NAME}:${IMAGE_TAG}"
            docker rmi "${IMAGE_NAME}:${IMAGE_TAG}" 2>/dev/null || true
        fi

        # Clean dangling images
        DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
        if [[ -n "$DANGLING_IMAGES" ]]; then
            print_status "Removing dangling images..."
            echo "$DANGLING_IMAGES" | xargs docker rmi 2>/dev/null || true
        fi

        # Clean build cache if requested
        if [[ "$USE_CACHE" == "false" ]]; then
            print_status "Cleaning Docker build cache..."
            docker builder prune -f > /dev/null 2>&1 || true
        fi

        print_success "Cleanup completed"
    fi
}

# Function to build Docker image
build_docker_image() {
    print_status "Building Docker image with advanced multi-stage optimization..."

    # Prepare build arguments
    BUILD_COMMAND="docker build"

    # Add BuildKit support
    if [[ "$BUILDKIT_ENABLED" == "true" ]]; then
        BUILD_COMMAND="DOCKER_BUILDKIT=1 $BUILD_COMMAND"
    fi

    # Add dockerfile
    BUILD_COMMAND="$BUILD_COMMAND -f $DOCKERFILE"

    # Add build arguments
    BUILD_COMMAND="$BUILD_COMMAND --build-arg CONFIG_FILE=$CONFIG_FILE"
    BUILD_COMMAND="$BUILD_COMMAND --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    BUILD_COMMAND="$BUILD_COMMAND --build-arg BUILD_VERSION=2.0-advanced"
    BUILD_COMMAND="$BUILD_COMMAND --build-arg VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

    # Add custom build args
    if [[ -n "$BUILD_ARGS" ]]; then
        BUILD_COMMAND="$BUILD_COMMAND $BUILD_ARGS"
    fi

    # Add platform specification
    if [[ "$MULTI_PLATFORM" == "true" ]]; then
        BUILD_COMMAND="$BUILD_COMMAND --platform linux/arm64,linux/amd64"
    else
        BUILD_COMMAND="$BUILD_COMMAND --platform linux/arm64"
    fi

    # Add cache options
    if [[ "$USE_CACHE" == "false" ]]; then
        BUILD_COMMAND="$BUILD_COMMAND --no-cache"
    fi

    # Add target for build type
    if [[ "$BUILD_TYPE" == "production" ]]; then
        BUILD_COMMAND="$BUILD_COMMAND --target runtime"
    fi

    # Add image tag
    BUILD_COMMAND="$BUILD_COMMAND -t ${IMAGE_NAME}:${IMAGE_TAG}"

    # Add context
    BUILD_COMMAND="$BUILD_COMMAND ."

    print_progress "Build command: $BUILD_COMMAND"

    # Execute build with progress indication
    if [[ "$DEBUG_MODE" == "true" ]]; then
        BUILD_COMMAND="$BUILD_COMMAND --progress=plain"
    fi

    print_status "Starting multi-stage build process..."

    # Measure build time
    BUILD_START_TIME=$(date +%s)

    if eval "$BUILD_COMMAND"; then
        BUILD_END_TIME=$(date +%s)
        BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))
        print_success "Docker image built successfully in ${BUILD_DURATION} seconds"

        # Display image information
        IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Size}}" | tail -n +2)
        IMAGE_ID=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.ID}}" | tail -n +2)
        print_status "Image ID: $IMAGE_ID"
        print_status "Image Size: $IMAGE_SIZE"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to push to registry
push_to_registry() {
    if [[ "$PUSH_TO_REGISTRY" == "true" ]] && [[ -n "$REGISTRY_URL" ]]; then
        print_status "Pushing image to registry: $REGISTRY_URL"

        REGISTRY_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

        # Tag for registry
        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$REGISTRY_IMAGE"

        # Push to registry
        if docker push "$REGISTRY_IMAGE"; then
            print_success "Image pushed to registry: $REGISTRY_IMAGE"
        else
            print_error "Failed to push image to registry"
            exit 1
        fi
    fi
}

# Function to run container
run_container() {
    if [[ "$RUN_AFTER_BUILD" == "true" ]]; then
        print_status "Starting container with advanced optimizations..."

        # Stop existing container
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true

        # Prepare run command
        RUN_COMMAND="docker run -d"
        RUN_COMMAND="$RUN_COMMAND --name $CONTAINER_NAME"
        RUN_COMMAND="$RUN_COMMAND --platform linux/arm64"
        RUN_COMMAND="$RUN_COMMAND -p 8282:8282"

        # Add volume mounts
        RUN_COMMAND="$RUN_COMMAND -v $(pwd)/models:/root/open-avatar-chat/models"
        RUN_COMMAND="$RUN_COMMAND -v $(pwd)/resource:/root/open-avatar-chat/resource"
        RUN_COMMAND="$RUN_COMMAND -v $(pwd)/ssl_certs:/root/open-avatar-chat/ssl_certs"
        RUN_COMMAND="$RUN_COMMAND -v $(pwd)/logs:/root/open-avatar-chat/logs"
        RUN_COMMAND="$RUN_COMMAND -v $(pwd)/temp:/root/open-avatar-chat/temp"

        # Add environment variables
        RUN_COMMAND="$RUN_COMMAND -e PYTORCH_ENABLE_MPS_FALLBACK=1"
        RUN_COMMAND="$RUN_COMMAND -e PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0"
        RUN_COMMAND="$RUN_COMMAND -e OMP_NUM_THREADS=8"
        RUN_COMMAND="$RUN_COMMAND -e MKL_NUM_THREADS=8"
        RUN_COMMAND="$RUN_COMMAND -e VECLIB_MAXIMUM_THREADS=8"
        RUN_COMMAND="$RUN_COMMAND -e NUMEXPR_NUM_THREADS=8"
        RUN_COMMAND="$RUN_COMMAND -e ACCELERATE_USE_CPU=1"
        RUN_COMMAND="$RUN_COMMAND -e CONFIG_FILE=$CONFIG_FILE"

        # Add resource limits
        RUN_COMMAND="$RUN_COMMAND --memory=$MEMORY_LIMIT"
        RUN_COMMAND="$RUN_COMMAND --cpus=$CPU_LIMIT"

        # Add monitoring if enabled
        if [[ "$ENABLE_MONITORING" == "true" ]]; then
            RUN_COMMAND="$RUN_COMMAND --log-driver=json-file"
            RUN_COMMAND="$RUN_COMMAND --log-opt max-size=100m"
            RUN_COMMAND="$RUN_COMMAND --log-opt max-file=5"
        fi

        # Add restart policy
        RUN_COMMAND="$RUN_COMMAND --restart unless-stopped"

        # Add health check override if needed
        RUN_COMMAND="$RUN_COMMAND --health-timeout=${HEALTH_CHECK_TIMEOUT}s"

        # Add image
        RUN_COMMAND="$RUN_COMMAND ${IMAGE_NAME}:${IMAGE_TAG}"

        print_debug "Run command: $RUN_COMMAND"

        if eval "$RUN_COMMAND"; then
            print_success "Container started successfully"
            print_status "Container name: $CONTAINER_NAME"
            print_status "Memory limit: $MEMORY_LIMIT"
            print_status "CPU limit: $CPU_LIMIT"
            print_status ""
            print_status "🌐 Access URLs:"
            print_status "  Web interface: https://localhost:8282"
            print_status "  Health check:  http://localhost:8282/health"
            print_status ""
            print_status "📋 Management Commands:"
            print_status "  View logs:     docker logs -f $CONTAINER_NAME"
            print_status "  Stop:          docker stop $CONTAINER_NAME"
            print_status "  Restart:       docker restart $CONTAINER_NAME"
            print_status "  Shell access:  docker exec -it $CONTAINER_NAME /bin/bash"
            print_status "  Remove:        docker rm -f $CONTAINER_NAME"

            # Wait for container to be ready
            print_status "⏳ Waiting for service to be ready..."
            for i in $(seq 1 $((HEALTH_CHECK_TIMEOUT/5))); do
                if docker exec "$CONTAINER_NAME" /usr/local/bin/healthcheck.sh > /dev/null 2>&1; then
                    print_success "🎉 Service is ready! Access it at https://localhost:8282"
                    break
                elif [[ $i -eq $((HEALTH_CHECK_TIMEOUT/5)) ]]; then
                    print_warning "Service might still be starting up. Check logs with: docker logs -f $CONTAINER_NAME"
                else
                    echo -n "."
                    sleep 5
                fi
            done
            echo ""

            # Show container stats if monitoring enabled
            if [[ "$ENABLE_MONITORING" == "true" ]]; then
                print_status "📊 Container Statistics:"
                docker stats --no-stream "$CONTAINER_NAME" | tail -n +2
            fi

        else
            print_error "Failed to start container"
            exit 1
        fi
    else
        print_success "Build completed successfully!"
        print_status "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
        print_status "To run manually: docker run -d --name $CONTAINER_NAME -p 8282:8282 ${IMAGE_NAME}:${IMAGE_TAG}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --dockerfile)
            DOCKERFILE="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --image-tag)
            IMAGE_TAG="$2"
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
        --no-parallel)
            PARALLEL_BUILD=false
            shift
            ;;
        --experimental)
            EXPERIMENTAL_FEATURES=true
            shift
            ;;
        --multi-platform)
            MULTI_PLATFORM=true
            shift
            ;;
        --memory)
            MEMORY_LIMIT="$2"
            shift 2
            ;;
        --cpu)
            CPU_LIMIT="$2"
            shift 2
            ;;
        --enable-monitoring)
            ENABLE_MONITORING=true
            shift
            ;;
        --push)
            PUSH_TO_REGISTRY=true
            shift
            ;;
        --registry)
            REGISTRY_URL="$2"
            shift 2
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --build-args)
            BUILD_ARGS="$2"
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
if [[ ! "$BUILD_TYPE" =~ ^(development|production|testing)$ ]]; then
    print_error "Invalid build type: $BUILD_TYPE. Must be 'development', 'production', or 'testing'"
    exit 1
fi

# Main execution
main() {
    local start_time=$(date +%s)

    # Print header
    echo ""
    print_status "🚀 OpenAvatarChat Mac M3 Advanced Build Script v2.0"
    print_status "=================================================="
    print_status "Build Type: $BUILD_TYPE"
    print_status "Dockerfile: $DOCKERFILE"
    print_status "Config File: $CONFIG_FILE"
    print_status "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    print_status "Container: $CONTAINER_NAME"
    if [[ "$DEBUG_MODE" == "true" ]]; then
        print_debug "Debug mode enabled"
    fi
    echo ""

    # Execute build steps
    check_system_requirements
    check_docker_requirements
    initialize_project
    clean_previous_builds
    build_docker_image
    push_to_registry
    run_container

    # Calculate total time
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    local minutes=$((total_time / 60))
    local seconds=$((total_time % 60))

    echo ""
    print_success "✅ Mac M3 Advanced Build Process Completed!"
    print_status "Total time: ${minutes}m ${seconds}s"
    print_status "=================================================="
    echo ""
}

# Handle script interruption
trap 'print_error "Build interrupted by user"; exit 130' INT

# Execute main function
main "$@"
