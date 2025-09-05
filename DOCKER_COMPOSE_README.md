# OpenAvatarChat Docker Compose Setup

This directory contains a complete Docker Compose setup for running OpenAvatarChat with both OpenAI and local Ollama options.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop (with Apple Silicon support)
- 16GB+ RAM recommended
- 20GB+ free disk space

### Option 1: Local AI with Ollama (Recommended)
```bash
# Setup and start local AI
./manage.sh setup-ollama
./manage.sh start-ollama

# Access at: https://localhost:8283
```

### Option 2: OpenAI Cloud AI
```bash
# Add your API key to .env file
echo "OPENAI_API_KEY=sk-your-key-here" > .env

# Setup and start OpenAI version
./manage.sh setup-openai
./manage.sh start-openai

# Access at: https://localhost:8282
```

## 📋 Available Services

| Service | Description | Port | Profile |
|---------|-------------|------|---------|
| **Ollama Server** | Local AI model server | 11434 | `ollama` |
| **OpenAvatarChat-Ollama** | Local AI chat interface | 8283 | `ollama` |
| **OpenAvatarChat-OpenAI** | Cloud AI chat interface | 8282 | `openai` |
| **Redis** | Optional caching layer | 6379 | `cache` |
| **Nginx** | Optional reverse proxy | 80/443 | `production` |

## 🛠 Management Commands

### Service Management
```bash
# Start services
./manage.sh start-ollama          # Start local AI
./manage.sh start-openai          # Start OpenAI version

# Stop services
./manage.sh stop-ollama           # Stop local AI
./manage.sh stop-openai           # Stop OpenAI version

# Check status
./manage.sh status                # Show all service status
```

### Logs and Monitoring
```bash
# View logs
./manage.sh logs-ollama --follow         # OpenAvatarChat logs
./manage.sh logs-ollama-server --follow  # Ollama server logs
./manage.sh logs-openai --follow         # OpenAI version logs

# Test services
./manage.sh test-ollama           # Test local AI
./manage.sh test-openai           # Test OpenAI version
```

### Model Management
```bash
# Manage Ollama models
./manage.sh models                # Interactive model management

# Backup/restore
./manage.sh backup                # Backup Ollama models
./manage.sh restore               # Restore from backup
```

### Maintenance
```bash
# Rebuild images
./manage.sh build                 # Rebuild all images

# Clean up
./manage.sh clean --force         # Remove containers and volumes
```

## 📁 Directory Structure

```
OpenAvatarChat/
├── docker-compose.yml           # Main compose file
├── manage.sh                     # Management script
├── ollama-entrypoint.sh          # Ollama startup script
├── Dockerfile.mac-m3             # Mac M3 optimized image
├── config/
│   ├── chat_with_ollama_mac_m3.yaml      # Ollama config
│   └── chat_with_openai_mac_m3.yaml      # OpenAI config
├── models/                       # Model storage (persistent)
├── logs/                         # Application logs
├── ssl_certs/                    # SSL certificates (auto-generated)
└── .env                          # Environment variables
```

## ⚙️ Configuration

### Environment Variables (.env)
```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Mac M3 Optimizations
PYTORCH_ENABLE_MPS_FALLBACK=1
OMP_NUM_THREADS=8
MKL_NUM_THREADS=8
VECLIB_MAXIMUM_THREADS=8
NUMEXPR_NUM_THREADS=8

# Optional: Model Cache
TRANSFORMERS_CACHE=/root/open-avatar-chat/models/transformers_cache
HF_HOME=/root/open-avatar-chat/models/huggingface_cache
```

### Docker Compose Profiles

| Profile | Services | Use Case |
|---------|----------|-----------|
| `ollama` | Ollama server + OpenAvatarChat | Local AI, privacy-focused |
| `openai` | OpenAI-powered OpenAvatarChat | Cloud AI, best performance |
| `cache` | Redis caching | Performance optimization |
| `production` | Nginx proxy | Production deployment |

## 🎯 Usage Examples

### Start Local AI (Privacy Mode)
```bash
# Complete local setup - no internet needed after models download
./manage.sh setup-ollama
./manage.sh start-ollama

# Models auto-download: qwen2.5vl, nomic-embed-text
# Access: https://localhost:8283
```

### Start Cloud AI (Performance Mode)
```bash
# Requires OpenAI API key
echo "OPENAI_API_KEY=sk-your-key" > .env
./manage.sh setup-openai
./manage.sh start-openai

# Uses GPT-3.5-turbo model
# Access: https://localhost:8282
```

### Run Both Versions
```bash
# Compare local vs cloud AI
./manage.sh start-ollama
./manage.sh start-openai

# Ollama: https://localhost:8283 (local, private)
# OpenAI: https://localhost:8282 (cloud, faster)
```

### Production Deployment
```bash
# Full production setup with caching and reverse proxy
docker compose --profile ollama --profile cache --profile production up -d

# Access via nginx on port 80/443
```

## 🔧 Advanced Configuration

### Custom Ollama Models
```bash
# Edit docker-compose.yml
environment:
  OLLAMA_AUTOPULL: "qwen2.5vl llama3:8b mistral:7b"

# Or manage interactively
./manage.sh models
```

### Resource Limits
```bash
# Adjust in docker-compose.yml for your system
deploy:
  resources:
    limits:
      memory: 16G    # Reduce for 16GB systems
      cpus: '8.0'    # Adjust for your CPU count
```

### Custom Configuration
```bash
# Create custom config files
cp config/chat_with_ollama_mac_m3.yaml config/my_custom.yaml

# Mount in docker-compose.yml
volumes:
  - ./config/my_custom.yaml:/root/open-avatar-chat/config/my_custom.yaml
```

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker
docker --version
docker compose version

# Check system resources
./manage.sh status
docker system df
```

**Models not downloading:**
```bash
# Check Ollama logs
./manage.sh logs-ollama-server --follow

# Manual model pull
docker compose exec ollama ollama pull qwen2.5vl
```

**Web interface not accessible:**
```bash
# Check SSL certificates
ls -la ssl_certs/

# Regenerate if needed
rm -rf ssl_certs/*
./manage.sh setup-ollama
```

**High memory usage:**
```bash
# Monitor resource usage
docker stats

# Reduce model size or system limits
./manage.sh models  # Choose smaller models
```

### Debug Commands
```bash
# Container inspection
docker compose --profile ollama ps
docker compose exec ollama ollama list
docker compose logs --tail 50 open-avatar-chat-ollama

# Network connectivity
docker network ls
docker compose exec open-avatar-chat-ollama curl http://ollama:11434/api/tags

# Volume inspection
docker volume ls
docker volume inspect ollama_data
```

## 📊 Performance Tuning

### Mac M3 Optimizations
```bash
# CPU threading (in docker-compose.yml)
environment:
  OMP_NUM_THREADS: 8        # Match your CPU cores
  MKL_NUM_THREADS: 8
  VECLIB_MAXIMUM_THREADS: 8

# Memory management
deploy:
  resources:
    limits:
      memory: 16G           # Adjust for available RAM
```

### Model Selection
| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|-----------|
| `qwen2.5:1.5b` | 1.5GB | Fast | Good | Testing, low memory |
| `qwen2.5:7b` | 4.7GB | Medium | Better | Balanced performance |
| `qwen2.5:14b` | 8.2GB | Slow | Best | High-end Mac M3 Max |
| `qwen2.5vl` | 4.7GB | Medium | Vision | Image + text input |

## 🔒 Security Notes

### SSL Certificates
- Self-signed certificates generated automatically
- For production, replace with valid certificates
- Located in `ssl_certs/` directory

### API Keys
- Never commit `.env` files to version control
- Use environment-specific API keys
- Rotate keys regularly

### Network Security
- Services isolated in Docker network
- Only necessary ports exposed
- Use reverse proxy for production

## 📈 Monitoring

### Health Checks
```bash
# Built-in health checks
docker compose ps  # Shows health status

# Manual health checks
curl -k https://localhost:8283/health  # OpenAvatarChat
curl http://localhost:11434/api/tags   # Ollama API
```

### Resource Monitoring
```bash
# Real-time resource usage
docker stats

# Disk usage
docker system df

# Model storage
du -sh models/
docker volume inspect ollama_data
```

## 🚀 Getting Started Checklist

- [ ] Install Docker Desktop with Apple Silicon support
- [ ] Clone repository and navigate to directory
- [ ] Choose setup: `./manage.sh setup-ollama` (local) or `./manage.sh setup-openai` (cloud)
- [ ] Set OpenAI API key in `.env` file (if using OpenAI)
- [ ] Start services: `./manage.sh start-ollama` or `./manage.sh start-openai`
- [ ] Access web interface: https://localhost:8283 (Ollama) or https://localhost:8282 (OpenAI)
- [ ] Test chat functionality
- [ ] Monitor logs: `./manage.sh logs-ollama --follow`

## 💡 Pro Tips

1. **Start with Ollama** - It's easier to set up and doesn't require API keys
2. **Monitor resource usage** - Mac M3 handles 7B models well, 14B+ needs more RAM
3. **Use both versions** - Compare local vs cloud AI performance
4. **Backup models regularly** - `./manage.sh backup` saves download time
5. **Check logs frequently** - `./manage.sh logs-ollama --follow` for debugging

---

For more help, run `./manage.sh --help` or check the main project documentation.