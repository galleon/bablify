#!/bin/bash

# OpenAvatarChat SSL Certificate Generator for Mac M3
# Generates self-signed SSL certificates for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if OpenSSL is available
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed"
        echo "Install it using: brew install openssl"
        exit 1
    fi

    openssl_version=$(openssl version)
    print_status "Using OpenSSL: $openssl_version"
}

# Create ssl_certs directory
create_directory() {
    if [[ ! -d "ssl_certs" ]]; then
        mkdir -p ssl_certs
        print_status "Created ssl_certs directory"
    fi
}

# Generate certificate configuration
create_config() {
    print_status "Creating certificate configuration..."

    cat > ssl_certs/openssl.cnf << 'EOF'
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=California
L=San Francisco
O=OpenAvatarChat
OU=Development
CN=localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = 127.0.0.1
DNS.4 = ::1
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = 0.0.0.0
EOF

    print_success "Certificate configuration created"
}

# Generate private key
generate_key() {
    print_status "Generating private key..."

    openssl genrsa -out ssl_certs/localhost.key 4096

    # Set proper permissions
    chmod 600 ssl_certs/localhost.key

    print_success "Private key generated: ssl_certs/localhost.key"
}

# Generate certificate
generate_cert() {
    print_status "Generating SSL certificate..."

    openssl req -new -x509 -key ssl_certs/localhost.key \
        -out ssl_certs/localhost.crt \
        -days 365 \
        -config ssl_certs/openssl.cnf \
        -extensions v3_req

    # Set proper permissions
    chmod 644 ssl_certs/localhost.crt

    print_success "SSL certificate generated: ssl_certs/localhost.crt"
}

# Verify certificate
verify_cert() {
    print_status "Verifying certificate..."

    # Check certificate details
    print_status "Certificate information:"
    openssl x509 -in ssl_certs/localhost.crt -text -noout | grep -E "(Subject:|DNS:|IP Address:|Not Before|Not After)"

    # Verify certificate and key match
    cert_md5=$(openssl x509 -noout -modulus -in ssl_certs/localhost.crt | openssl md5)
    key_md5=$(openssl rsa -noout -modulus -in ssl_certs/localhost.key | openssl md5)

    if [[ "$cert_md5" == "$key_md5" ]]; then
        print_success "Certificate and key match"
    else
        print_error "Certificate and key do not match!"
        exit 1
    fi
}

# Add to macOS keychain (optional)
add_to_keychain() {
    print_status "Adding certificate to macOS keychain..."

    # Add certificate to system keychain
    if sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ssl_certs/localhost.crt; then
        print_success "Certificate added to macOS keychain"
        print_warning "You may need to restart your browser"
    else
        print_warning "Failed to add to keychain (this is optional)"
        print_status "You can manually trust the certificate in your browser"
    fi
}

# Test certificate
test_cert() {
    print_status "Testing certificate with OpenSSL..."

    # Start a test server in the background
    openssl s_server -cert ssl_certs/localhost.crt -key ssl_certs/localhost.key -port 9999 -www &
    server_pid=$!

    sleep 2

    # Test connection
    if echo "GET /" | openssl s_client -connect localhost:9999 -servername localhost >/dev/null 2>&1; then
        print_success "Certificate test passed"
    else
        print_warning "Certificate test failed (this might be normal)"
    fi

    # Kill test server
    kill $server_pid 2>/dev/null || true
}

# Show usage
show_usage() {
    print_header "SSL Certificate Generator"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --keychain    Add certificate to macOS keychain"
    echo "  --test        Test the generated certificate"
    echo "  --force       Overwrite existing certificates"
    echo "  --help        Show this help message"
    echo ""
    echo "The script will generate:"
    echo "  ssl_certs/localhost.key  - Private key"
    echo "  ssl_certs/localhost.crt  - SSL certificate"
    echo "  ssl_certs/openssl.cnf    - OpenSSL configuration"
}

# Parse command line arguments
ADD_TO_KEYCHAIN=false
TEST_CERT=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --keychain)
            ADD_TO_KEYCHAIN=true
            shift
            ;;
        --test)
            TEST_CERT=true
            shift
            ;;
        --force)
            FORCE=true
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

# Main execution
main() {
    print_header "Generating SSL Certificates for OpenAvatarChat"

    # Check if certificates already exist
    if [[ -f "ssl_certs/localhost.crt" || -f "ssl_certs/localhost.key" ]] && [[ "$FORCE" != "true" ]]; then
        print_warning "SSL certificates already exist!"
        echo "Use --force to overwrite existing certificates"
        exit 1
    fi

    check_openssl
    create_directory
    create_config
    generate_key
    generate_cert
    verify_cert

    if [[ "$ADD_TO_KEYCHAIN" == "true" ]]; then
        add_to_keychain
    fi

    if [[ "$TEST_CERT" == "true" ]]; then
        test_cert
    fi

    print_header "Certificate Generation Complete"
    print_success "SSL certificates generated successfully!"
    print_status "Files created:"
    echo "  ssl_certs/localhost.key  ($(stat -f%z ssl_certs/localhost.key) bytes)"
    echo "  ssl_certs/localhost.crt  ($(stat -f%z ssl_certs/localhost.crt) bytes)"
    echo "  ssl_certs/openssl.cnf    ($(stat -f%z ssl_certs/openssl.cnf) bytes)"
    echo ""
    print_status "Next steps:"
    echo "1. Restart OpenAvatarChat: ./manage.sh restart-ollama"
    echo "2. Access https://localhost:8283 in your browser"
    echo "3. Accept the self-signed certificate warning"
    echo ""
    print_warning "For production use, obtain certificates from a trusted CA"
}

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "This script must be run from the OpenAvatarChat directory"
    exit 1
fi

# Run main function
main "$@"
