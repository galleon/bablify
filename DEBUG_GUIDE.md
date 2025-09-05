# 🔧 OpenAvatarChat Debugging Guide for Mac M3

## 🚀 Quick Status Check

```bash
# Check everything is working
./manage.sh status

# Quick health check
./debug_mac_m3.sh health
```

**Expected Output:**
- ✅ Ollama interface: https://localhost:8283 (accessible)
- ✅ Ollama API: http://localhost:11434 (accessible)
- ✅ Models: qwen2.5vl:latest, nomic-embed-text:latest

## 🔥 Emergency Fixes

### Service Won't Start
```bash
# Stop everything and restart clean
./manage.sh stop-ollama
docker system prune -f
./manage.sh start-ollama
```

### Web Interface Not Loading
```bash
# Check if service is actually running
curl -k https://localhost:8283/

# If not responding, check logs
./manage.sh logs-ollama --follow
```

### Models Not Loading
```bash
# Check Ollama server logs
./manage.sh logs-ollama-server --follow

# Test API directly
curl http://localhost:11434/api/tags

# Manually pull models if needed
docker compose exec ollama ollama pull qwen2.5vl
```

### High Memory Usage
```bash
# Check resource usage
docker stats

# Restart services to clear memory
./manage.sh restart-ollama
```

## 📊 Debugging Tools

### Real-time Monitoring
```bash
# Continuous performance monitoring
./debug_mac_m3.sh monitor

# Follow logs in real-time
./manage.sh logs-ollama --follow
```

### System Information
```bash
# Check Mac M3 system info
./debug_mac_m3.sh system

# Check Docker resources
docker system df
docker system info
```

### Network Debugging
```bash
# Test all network connections
./debug_mac_m3.sh network

# Test specific endpoints
curl -k https://localhost:8283/
curl http://localhost:11434/api/tags
```

### Performance Testing
```bash
# Run benchmarks
./debug_mac_m3.sh benchmark

# Test model performance
./debug_mac_m3.sh models
```

## 🐛 Common Issues & Solutions

### Issue: "Container Won't Start"
**Symptoms:** Docker compose up fails, container exits immediately
```bash
# Solution:
docker compose --profile ollama logs
docker system prune -f
./manage.sh clean --force
./manage.sh setup-ollama
```

### Issue: "Web Interface Shows 502/503 Error"
**Symptoms:** Browser shows bad gateway or service unavailable
```bash
# Solution:
# Wait for service to fully start (can take 2-3 minutes)
./debug_mac_m3.sh health
# Check if SSL certificates exist
ls -la ssl_certs/
```

### Issue: "Model Generation is Slow"
**Symptoms:** Responses take >30 seconds
```bash
# Solution:
# Check system resources
./debug_mac_m3.sh performance
# Consider using smaller model
docker compose exec ollama ollama pull qwen2.5:7b
```

### Issue: "Out of Memory Errors"
**Symptoms:** Containers crash with OOM errors
```bash
# Solution:
# Check available memory
vm_stat
# Reduce memory limits in docker-compose.yml
# Or close other applications
```

### Issue: "Cannot Connect to Ollama API"
**Symptoms:** API calls fail with connection refused
```bash
# Solution:
# Check if Ollama container is healthy
docker compose ps ollama
# Test internal connectivity
docker compose exec open-avatar-chat-ollama curl http://ollama:11434/api/tags
```

## 📝 Log Analysis

### Important Log Locations
```bash
# Application logs
./manage.sh logs-ollama

# Ollama server logs  
./manage.sh logs-ollama-server

# All services
docker compose logs --tail 100
```

### Log Patterns to Look For

**✅ Healthy Startup:**
```
INFO: Uvicorn running on https://0.0.0.0:8282
Handler RtcClient loaded
Handler LLMOpenAICompatible loaded
```

**❌ Problems:**
```
ConnectionRefusedError: [Errno 61] Connection refused
OOM killed
ImportError: No module named
```

### Analyze Recent Logs
```bash
# Get structured log analysis
./debug_mac_m3.sh logs

# Search for specific errors
docker compose logs | grep -i error
docker compose logs | grep -i "connection refused"
```

## ⚡ Performance Optimization

### Mac M3 Specific Optimizations

1. **Memory Management:**
```bash
# Check current settings in docker-compose.yml
grep -A 10 "deploy:" docker-compose.yml
```

2. **CPU Threading:**
```yaml
environment:
  OMP_NUM_THREADS: 8        # Match your CPU cores
  MKL_NUM_THREADS: 8
  VECLIB_MAXIMUM_THREADS: 8
```

3. **Model Selection:**
```bash
# For better performance on Mac M3:
# - qwen2.5:1.5b (fast, 1.5GB)
# - qwen2.5:7b (balanced, 4.7GB) 
# - qwen2.5vl (vision, 4.7GB) ← Currently used
```

### Resource Monitoring
```bash
# Real-time system monitoring
htop                          # CPU/Memory overview
docker stats                  # Container resources
./debug_mac_m3.sh monitor     # Continuous monitoring
```

## 🔧 Configuration Files

### Key Files to Check

1. **docker-compose.yml** - Main service configuration
2. **config/chat_with_ollama_mac_m3.yaml** - App configuration
3. **.env** - Environment variables (if using OpenAI)
4. **ssl_certs/** - SSL certificates for HTTPS

### Config Validation
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('config/chat_with_ollama_mac_m3.yaml'))"

# Check Docker compose file
docker compose config
```

## 🌐 Network Troubleshooting

### Port Mapping
- **8283** → Web Interface (HTTPS)
- **11434** → Ollama API (HTTP)
- **6379** → Redis (Internal)

### Test Connectivity
```bash
# From host machine
curl -k https://localhost:8283/
curl http://localhost:11434/api/tags

# From inside containers
docker compose exec open-avatar-chat-ollama curl http://ollama:11434/api/tags
```

### Firewall Issues
```bash
# Check if ports are blocked
sudo lsof -i :8283
sudo lsof -i :11434

# macOS Firewall check
sudo pfctl -sr | grep 8283
```

## 🚨 Emergency Recovery

### Complete Reset
```bash
# Nuclear option - reset everything
./manage.sh stop-ollama
docker compose down -v
docker system prune -f
rm -rf models/* logs/* ssl_certs/*
./manage.sh setup-ollama
./manage.sh start-ollama
```

### Backup Models Before Reset
```bash
# Backup your models
./manage.sh backup

# After reset, restore models
./manage.sh restore
```

## 📱 Quick Commands Reference

```bash
# Service Management
./manage.sh start-ollama          # Start services
./manage.sh stop-ollama           # Stop services  
./manage.sh restart-ollama        # Restart services
./manage.sh status                # Check status

# Debugging
./debug_mac_m3.sh health          # Health check
./debug_mac_m3.sh monitor         # Real-time monitoring
./debug_mac_m3.sh troubleshoot    # Full diagnostic
./debug_mac_m3.sh fix             # Auto-fix issues

# Logs
./manage.sh logs-ollama --follow  # Follow app logs
./manage.sh logs-ollama-server    # Ollama server logs

# Models
./manage.sh models                # Model management
docker compose exec ollama ollama list
```

## 🎯 Testing Checklist

- [ ] **Services Running:** `./manage.sh status` shows all healthy
- [ ] **Web Access:** https://localhost:8283 loads
- [ ] **API Access:** `curl http://localhost:11434/api/tags` returns models
- [ ] **Model Response:** Send test message through web interface
- [ ] **Performance:** Response time < 30 seconds
- [ ] **Logs Clean:** No errors in recent logs
- [ ] **Resources OK:** Memory usage < 80% of available

## 💡 Pro Tips for Mac M3

1. **Memory:** Keep 8GB+ free for optimal performance
2. **Models:** Start with qwen2.5:7b for best balance
3. **Monitoring:** Use `./debug_mac_m3.sh monitor` during development
4. **Logs:** Always check logs first: `./manage.sh logs-ollama --follow`
5. **Docker:** Restart Docker Desktop if containers won't start
6. **Network:** Use localhost, not 127.0.0.1 for better compatibility

---

## 🆘 Still Having Issues?

1. **Run full diagnostic:** `./debug_mac_m3.sh troubleshoot`
2. **Check system requirements:** 16GB+ RAM, 20GB+ free disk space
3. **Update Docker Desktop** to latest version
4. **Restart your Mac** if Docker behaves strangely
5. **Check Docker Desktop settings:** Ensure Apple Silicon support enabled

For more help, check the logs with `./manage.sh logs-ollama --follow` and look for specific error messages.