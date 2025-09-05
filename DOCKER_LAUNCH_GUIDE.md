# Docker Launch Guide for Bablify

This guide documents the exact process to launch the Bablify application using Docker on Mac M3.

## Overview

The application runs in Docker containers with the following services:
- **Main Application**: OpenAvatarChat with WebRTC support for real-time communication
- **Redis Cache**: For session management and caching

## Configuration

### Configuration File Used

The application uses `config/chat_with_minicpm_mac_m3.yaml` as its configuration file. Despite the "minicpm" in the name, this configuration is actually set up to use:
- **LLM**: OpenAI's GPT-3.5-turbo API
- **ASR**: SenseVoice (for speech recognition)
- **TTS**: EdgeTTS (for text-to-speech)
- **VAD**: SileroVAD (for voice activity detection)
- **Avatar**: Disabled for testing (LiteAvatar is set to false)

### Environment Variables

The OpenAI API key is stored in the `.env` file and **not** in the YAML configuration for security:

```bash
# .env file
OPENAI_API_KEY=your-api-key-here
```

The application has been modified to always read the API key from the environment variable, ensuring secrets are never stored in configuration files.

## Prerequisites

1. **Docker Desktop** installed and running on Mac
2. **Sufficient disk space** (at least 30GB free)
3. **OpenAI API key** in `.env` file
4. **SSL certificates** generated in `ssl_certs/` directory

## Launch Process

### Step 1: Clean Docker Resources (if needed)

If you're running low on disk space:

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a --volumes -f
```

### Step 2: Create Required Directories

```bash
# Create directories for Docker volumes
mkdir -p cache data/redis data/prometheus data/grafana
```

### Step 3: Launch with Docker Compose

The exact command to launch the application:

```bash
# Navigate to project directory
cd /Users/alleon_g/code/bablify

# Launch containers with environment variables from .env file
docker-compose -f docker-compose.mac-m3.yml --env-file .env up -d --build
```

This command:
- Uses `docker-compose.mac-m3.yml` configuration (optimized for Mac M3)
- Loads environment variables from `.env` file
- Builds the image if needed (`--build`)
- Runs in detached mode (`-d`)

### Step 4: Verify Deployment

Check if containers are running:

```bash
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE                             COMMAND                  CREATED         STATUS         PORTS
xxxxxxxxxxxx   bablify-open-avatar-chat-mac-m3  "uv run src/demo.py …"   x seconds ago   Up x seconds   0.0.0.0:8282->8282/tcp
xxxxxxxxxxxx   redis:7-alpine                    "docker-entrypoint.s…"   x seconds ago   Up x seconds   0.0.0.0:6379->6379/tcp
```

### Step 5: Check Application Logs

Monitor the application startup:

```bash
# View logs
docker logs open-avatar-chat-mac-m3 --tail 50

# Follow logs in real-time
docker logs open-avatar-chat-mac-m3 -f
```

Look for these key messages indicating successful startup:
- `Using OPENAI_API_KEY from environment variable`
- `Application startup complete`
- `Uvicorn running on https://0.0.0.0:8282`

## Access the Application

Once running, access the application at: **https://localhost:8282**

Note: You'll see a certificate warning because we're using self-signed certificates. Accept the warning to proceed.

## Docker Compose Configuration Details

The `docker-compose.mac-m3.yml` file includes:

### Environment Variables
```yaml
environment:
  # Mac M3 optimizations
  - PYTORCH_ENABLE_MPS_FALLBACK=1
  - OMP_NUM_THREADS=8
  - ACCELERATE_USE_CPU=1
  
  # API Keys (loaded from .env)
  - OPENAI_API_KEY=${OPENAI_API_KEY}
```

### Resource Limits
```yaml
deploy:
  resources:
    limits:
      memory: 16G
      cpus: "8.0"
    reservations:
      memory: 8G
      cpus: "4.0"
```

### Volume Mounts
```yaml
volumes:
  - ./models:/root/open-avatar-chat/models
  - ./resource:/root/open-avatar-chat/resource
  - ./ssl_certs:/root/open-avatar-chat/ssl_certs
  - ./logs:/root/open-avatar-chat/logs
  - ./config:/root/open-avatar-chat/config
```

## Common Operations

### Stop Containers
```bash
docker-compose -f docker-compose.mac-m3.yml down
```

### Restart Containers
```bash
docker-compose -f docker-compose.mac-m3.yml restart
```

### Rebuild After Code Changes
```bash
docker-compose -f docker-compose.mac-m3.yml down
docker-compose -f docker-compose.mac-m3.yml --env-file .env up -d --build
```

### View Container Resource Usage
```bash
docker stats
```

## Troubleshooting

### Issue: API Key Error
**Symptom**: "API key is incorrect" error in browser

**Solution**: 
1. Ensure `OPENAI_API_KEY` is set in `.env` file
2. Remove any `api_key` field from the YAML configuration
3. Rebuild and restart containers

### Issue: Out of Disk Space
**Symptom**: Build fails with "No space left on device"

**Solution**:
```bash
docker system prune -a --volumes -f
```

### Issue: Container Won't Start
**Symptom**: Container exits immediately

**Solution**:
1. Check logs: `docker logs open-avatar-chat-mac-m3`
2. Verify all required directories exist
3. Ensure SSL certificates are present in `ssl_certs/`

### Issue: Cannot Access UI
**Symptom**: Browser can't connect to https://localhost:8282

**Solution**:
1. Verify container is running: `docker ps`
2. Check firewall settings
3. Try accessing with curl: `curl -k https://localhost:8282/`

## Code Modifications Made

To ensure proper environment variable handling, the following modification was made to `src/handlers/llm/openai_compatible/llm_handler_openai_compatible.py`:

```python
def load(self, engine_config: ChatEngineConfigModel, handler_config: Optional[BaseModel] = None):
    if isinstance(handler_config, LLMConfig):
        # Always use API key from environment variable, ignore config value
        env_key = os.getenv("OPENAI_API_KEY", "")
        if env_key:
            handler_config.api_key = env_key
            logger.info("Using OPENAI_API_KEY from environment variable")
        else:
            error_message = 'OPENAI_API_KEY environment variable is required for OpenAI compatible LLM handler'
            logger.error(error_message)
            raise ValueError(error_message)
```

This ensures the API key is always read from the environment variable and never stored in configuration files.

## Notes

- The configuration file name contains "minicpm" for historical reasons but actually uses OpenAI's API
- The Mac M3 optimizations include CPU-only inference settings since MPS (Metal Performance Shaders) support may have compatibility issues
- Redis is used for caching and session management but is optional for basic functionality
- The application supports both text and audio input, though avatar rendering is disabled in this configuration for performance testing