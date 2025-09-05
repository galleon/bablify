#!/bin/bash

# Simple Mac M3 Test Build Script
# Minimal, tested version that actually works

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKERFILE="Dockerfile.mac-m3-simple"
IMAGE_NAME="open-avatar-chat"
IMAGE_TAG="mac-m3-test"
CONTAINER_NAME="open-avatar-chat-mac-m3-test"
CONFIG_FILE="config/chat_with_minicpm_mac_m3.yaml"

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

print_status "🧪 Mac M3 Test Build - Simple & Working Version"
print_status "=============================================="

# Check prerequisites
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Stop and remove existing container
print_status "Cleaning up existing container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Build the image
print_status "Building Docker image..."
BUILD_START=$(date +%s)

if docker build \
    --build-arg CONFIG_FILE="$CONFIG_FILE" \
    --platform linux/arm64 \
    -f "$DOCKERFILE" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .; then

    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    print_success "Build completed in ${BUILD_TIME} seconds"

    # Show image info
    IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Size}}" | tail -n +2)
    print_status "Image size: $IMAGE_SIZE"
else
    print_error "Build failed"
    exit 1
fi

# Run the container
print_status "Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --platform linux/arm64 \
    -p 8282:8282 \
    -v "$(pwd)/models:/root/open-avatar-chat/models" \
    -v "$(pwd)/resource:/root/open-avatar-chat/resource" \
    -v "$(pwd)/ssl_certs:/root/open-avatar-chat/ssl_certs" \
    -v "$(pwd)/logs:/root/open-avatar-chat/logs" \
    -e PYTORCH_ENABLE_MPS_FALLBACK=1 \
    -e OMP_NUM_THREADS=8 \
    -e ACCELERATE_USE_CPU=1 \
    --memory=16g \
    --cpus=8.0 \
    --restart unless-stopped \
    "${IMAGE_NAME}:${IMAGE_TAG}"

print_success "Container started: $CONTAINER_NAME"
print_status ""
print_status "🌐 Access: https://localhost:8282"
print_status "📋 Logs: docker logs -f $CONTAINER_NAME"
print_status "🛑 Stop: docker stop $CONTAINER_NAME"

# Wait for startup
print_status "⏳ Waiting for service to start..."
for i in {1..20}; do
    if docker logs "$CONTAINER_NAME" 2>&1 | grep -q "Running on"; then
        print_success "🎉 Service is running!"
        break
    elif [[ $i -eq 20 ]]; then
        print_warning "Service is taking longer to start. Check logs."
        docker logs "$CONTAINER_NAME" 2>&1 | tail -10
    else
        echo -n "."
        sleep 3
    fi
done

print_success "✅ Test build completed successfully!"
