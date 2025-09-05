# OpenAvatarChat Setup Guide

This guide covers the configuration and API keys needed to run OpenAvatarChat, especially for the Mac M3 optimized version.

## 🔑 API Keys and Configuration Overview

### ⚡ Quick Start (No API Keys Required)

The **Mac M3 version with MiniCPM** configuration requires **NO API keys** for basic functionality:

```bash
# Use the default MiniCPM config (no API keys needed)
./build_mac_m3.sh --config config/chat_with_minicpm_mac_m3.yaml
```

This configuration uses:
- **MiniCPM-o-2_6**: Local AI model (downloads automatically)
- **Silero VAD**: Local voice activity detection
- **LiteAvatar**: Local avatar rendering

## 📋 Configuration Options

### 1. Local-Only Setup (Recommended for Mac M3)

**Configuration**: `config/chat_with_minicpm_mac_m3.yaml`

✅ **No API keys required**
- All models run locally
- Complete privacy (no data sent to external services)
- Works offline after initial model download
- Optimized for Mac M3 performance

**What you get**:
- Text chat with AI
- Voice input/output
- Avatar animation
- Video input processing

### 2. Cloud-Enhanced Setup

**Configuration**: `config/chat_with_openai_compatible_mac_m3.yaml`

🔑 **Requires API keys** (choose one):

#### Option A: Alibaba DashScope (Recommended)
```bash
export DASHSCOPE_API_KEY="your_dashscope_api_key_here"
```

**How to get DashScope API Key**:
1. Visit [DashScope Console](https://dashscope.aliyuncs.com/)
2. Sign up/login with Alibaba Cloud account
3. Go to API Keys section
4. Create a new API key
5. Copy the key (format: `sk-xxxxxxxxxx`)

**Supported Models**:
- `qwen-plus` (recommended)
- `qwen-max`
- `qwen-turbo`

#### Option B: OpenAI Compatible APIs
```bash
export OPENAI_API_KEY="your_openai_api_key_here"
```

**Supported Services**:
- OpenAI GPT models
- Google Gemini (via OpenAI compatible endpoint)
- Local Ollama server
- Other OpenAI-compatible APIs

### 3. Advanced Cloud Setup

For maximum features, you can use multiple cloud services:

```yaml
# config/advanced_cloud.yaml
LLMOpenAICompatible:
  api_key: "${DASHSCOPE_API_KEY}"
  api_url: "https://dashscope.aliyuncs.com/compatible-mode/v1"
  model_name: "qwen-plus"

CosyVoice:
  api_key: "${DASHSCOPE_API_KEY}"
  model_name: "cosyvoice-v1"
  voice: "longxiaochun"
```

## 🛠 Configuration Methods

### Method 1: Environment Variables (Recommended)

Create a `.env` file in the project root:

```bash
# .env file
DASHSCOPE_API_KEY=sk-your-dashscope-key-here
OPENAI_API_KEY=sk-your-openai-key-here
```

### Method 2: Direct Configuration

Edit the YAML config file directly:

```yaml
# config/your_config.yaml
LLMOpenAICompatible:
  api_key: "sk-your-api-key-here"  # Direct key (not recommended for production)
```

### Method 3: Docker Environment Variables

When using Docker:

```bash
docker run -d \
  -e DASHSCOPE_API_KEY="your_key_here" \
  -e OPENAI_API_KEY="your_key_here" \
  open-avatar-chat:mac-m3
```

Or in `docker-compose.mac-m3.yml`:

```yaml
environment:
  - DASHSCOPE_API_KEY=your_key_here
  - OPENAI_API_KEY=your_key_here
```

## 📁 Configuration Files Explained

### Default Configurations

| Config File | Description | API Keys Required |
|-------------|-------------|-------------------|
| `chat_with_minicpm_mac_m3.yaml` | Local-only, Mac M3 optimized | ❌ None |
| `chat_with_openai_compatible.yaml` | Cloud LLM + local TTS/Avatar | ✅ LLM API key |
| `chat_with_qwen_omni.yaml` | Full cloud integration | ✅ DashScope API key |

### Custom Configuration

Create your own config by copying and modifying:

```bash
# Copy base config
cp config/chat_with_minicpm_mac_m3.yaml config/my_custom.yaml

# Edit as needed
vim config/my_custom.yaml

# Use with build script
./build_mac_m3.sh --config config/my_custom.yaml
```

## 🚀 Quick Setup Scenarios

### Scenario 1: Just Want to Try It (Easiest)

```bash
# No configuration needed
git clone <repo>
cd OpenAvatarChat
./build_mac_m3.sh
# Access: https://localhost:8282
```

### Scenario 2: Better AI Responses

```bash
# Get DashScope API key from https://dashscope.aliyuncs.com/
export DASHSCOPE_API_KEY="sk-your-key-here"

# Use cloud-enhanced config
./build_mac_m3.sh --config config/chat_with_openai_compatible.yaml
```

### Scenario 3: Production Setup

```bash
# Create production environment file
cat > .env << EOF
DASHSCOPE_API_KEY=sk-your-production-key
LOG_LEVEL=INFO
MODEL_CACHE_DIR=/data/models
EOF

# Use production build
./build_mac_m3.sh --build-type production --config config/production.yaml
```

## 🔧 Model Downloads and Storage

### Automatic Model Downloads

Models are automatically downloaded on first run:

**MiniCPM Models** (~6-12GB):
- `MiniCPM-o-2_6`: Full precision model
- `MiniCPM-o-2_6-int4`: Quantized model (recommended for Mac M3)

**Avatar Models** (~500MB):
- LiteAvatar assets
- Face detection models

**TTS/ASR Models** (~1-2GB):
- Silero VAD
- SenseVoice ASR
- CosyVoice TTS (if used)

### Model Storage Locations

```bash
# Local development
./models/                    # Project models directory

# Docker containers
/root/open-avatar-chat/models/  # Container models directory

# Cache locations
~/.cache/huggingface/       # HuggingFace models cache
~/.cache/modelscope/        # ModelScope models cache
```

### Manual Model Management

```bash
# Check model storage
du -sh models/

# Clear model cache (will re-download on next run)
rm -rf models/*

# Pre-download models (optional)
python -c "from modelscope import AutoModel; AutoModel.from_pretrained('openbmb/MiniCPM-o-2_6')"
```

## 🔒 Security Best Practices

### API Key Security

1. **Never commit API keys to git**:
   ```bash
   # Add to .gitignore
   echo ".env" >> .gitignore
   echo "*.key" >> .gitignore
   ```

2. **Use environment variables**:
   ```bash
   # Good
   export DASHSCOPE_API_KEY="sk-xxx"
   
   # Bad - don't put keys directly in config files
   api_key: "sk-xxx"
   ```

3. **Rotate keys regularly**:
   - Generate new API keys monthly
   - Revoke old keys when rotating

4. **Use different keys for different environments**:
   ```bash
   # Development
   export DASHSCOPE_API_KEY="sk-dev-xxx"
   
   # Production
   export DASHSCOPE_API_KEY="sk-prod-xxx"
   ```

### Network Security

1. **Use HTTPS** (enabled by default):
   - SSL certificates are auto-generated
   - Access via `https://localhost:8282`

2. **Firewall configuration**:
   ```bash
   # Only allow local access
   host: "127.0.0.1"  # Instead of "0.0.0.0"
   ```

## 🐛 Troubleshooting

### Common Configuration Issues

1. **API Key Not Found**:
   ```
   Error: DASHSCOPE_API_KEY is required
   ```
   **Solution**: Set the environment variable or add to config file

2. **Model Download Fails**:
   ```
   Error: Failed to download model
   ```
   **Solutions**:
   - Check internet connection
   - Verify disk space (need 20GB+ free)
   - Try clearing model cache

3. **SSL Certificate Errors**:
   ```
   Error: Certificate verification failed
   ```
   **Solutions**:
   - Use `https://` not `http://`
   - Regenerate certificates: `rm -rf ssl_certs/*` then restart

4. **Container Won't Start**:
   ```
   Error: Container exits immediately
   ```
   **Solutions**:
   - Check Docker logs: `docker logs open-avatar-chat-mac-m3`
   - Verify config file exists
   - Check available memory (need 8GB+)

### Validation Commands

```bash
# Test API key
curl -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
  https://dashscope.aliyuncs.com/compatible-mode/v1/models

# Test config file
python -c "import yaml; yaml.safe_load(open('config/your_config.yaml'))"

# Test Docker setup
docker run --rm open-avatar-chat:mac-m3 --help

# Test SSL certificates
openssl x509 -in ssl_certs/localhost.crt -text -noout
```

## 📊 Performance Optimization by Configuration

### For 16GB Mac M3:
```yaml
MiniCPM-o:
  model_name: "MiniCPM-o-2_6-int4"  # Use quantized model
  max_memory_gb: 8
  low_cpu_mem_usage: true

LiteAvatar:
  fps: 15  # Reduce frame rate
  low_memory_mode: true
```

### For 32GB+ Mac M3 Max:
```yaml
MiniCPM-o:
  model_name: "MiniCPM-o-2_6"  # Full precision model
  max_memory_gb: 16
  batch_size: 2  # Can handle larger batches

LiteAvatar:
  fps: 25  # Higher quality
  enable_fast_mode: true
```

## 🔄 Configuration Updates

### Updating Configurations

```bash
# Pull latest configs
git pull origin main

# Backup your custom config
cp config/my_custom.yaml config/my_custom.yaml.backup

# Merge new features
# (manually compare and update your config)

# Rebuild with new config
./build_mac_m3.sh --clean --config config/my_custom.yaml
```

### Config Version Compatibility

Check if your config is compatible:

```bash
# Validate config against current version
docker run --rm -v "$(pwd)/config:/config" \
  open-avatar-chat:mac-m3 python -c "
import yaml
config = yaml.safe_load(open('/config/your_config.yaml'))
print('Config validation passed')
"
```

## 🎯 Next Steps

After setup:

1. **Test the basic setup**: Access `https://localhost:8282`
2. **Try different features**: Text chat, voice input, avatar animation
3. **Monitor performance**: Check CPU/memory usage in Activity Monitor
4. **Customize configuration**: Adjust settings for your use case
5. **Explore advanced features**: Video input, multiple models, API integrations

For more detailed usage instructions, see the main README.md file.