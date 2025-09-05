#!/usr/bin/env python3
"""
WebRTC Connection Debugging Script for OpenAvatarChat (UV Project)

This script helps debug WebRTC connection issues, particularly DataChannel state problems.
It provides comprehensive logging and diagnostics for troubleshooting WebRTC connectivity.

Usage with UV:
    uv run debug_webrtc_connection.py [BASE_URL]

Examples:
    uv run debug_webrtc_connection.py
    uv run debug_webrtc_connection.py http://localhost:8080
    uv run debug_webrtc_connection.py https://myserver.com:8443
"""

import asyncio
import json
import logging
import time
from typing import Dict, Optional
import aiohttp
import sys
import os

# Setup logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('webrtc_debug.log')
    ]
)

logger = logging.getLogger(__name__)

class WebRTCDebugger:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url.rstrip('/')
        self.session: Optional[aiohttp.ClientSession] = None

    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()

    async def test_server_connectivity(self) -> bool:
        """Test if the server is reachable."""
        logger.info("Testing server connectivity...")
        try:
            async with self.session.get(f"{self.base_url}/") as response:
                if response.status == 200:
                    logger.info("✅ Server is reachable")
                    return True
                else:
                    logger.error(f"❌ Server returned status {response.status}")
                    return False
        except Exception as e:
            logger.error(f"❌ Failed to connect to server: {e}")
            return False

    async def test_config_endpoint(self) -> Optional[Dict]:
        """Test the configuration endpoint."""
        logger.info("Testing configuration endpoint...")
        try:
            async with self.session.get(f"{self.base_url}/openavatarchat/initconfig") as response:
                if response.status == 200:
                    config = await response.json()
                    logger.info("✅ Configuration endpoint working")
                    logger.debug(f"Config: {json.dumps(config, indent=2)}")

                    # Validate RTC configuration
                    if 'rtc_configuration' in config:
                        rtc_config = config['rtc_configuration']
                        if 'iceServers' in rtc_config:
                            ice_servers = rtc_config['iceServers']
                            logger.info(f"✅ Found {len(ice_servers)} ICE servers")
                            for i, server in enumerate(ice_servers):
                                logger.debug(f"  ICE Server {i+1}: {server}")
                        else:
                            logger.warning("⚠️  No ICE servers found in configuration")
                    else:
                        logger.error("❌ No RTC configuration found")

                    return config
                else:
                    logger.error(f"❌ Config endpoint returned status {response.status}")
                    return None
        except Exception as e:
            logger.error(f"❌ Failed to get configuration: {e}")
            return None

    async def test_webrtc_offer_endpoint(self) -> bool:
        """Test the WebRTC offer endpoint with a mock offer."""
        logger.info("Testing WebRTC offer endpoint...")

        # Mock SDP offer (minimal valid SDP)
        mock_offer = {
            "webrtc_id": f"debug-test-{int(time.time())}",
            "type": "offer",
            "sdp": """v=0
o=- 123456789 123456789 IN IP4 127.0.0.1
s=-
t=0 0
m=audio 9 UDP/TLS/RTP/SAVPF 111
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=ice-ufrag:test
a=ice-pwd:testpassword
a=fingerprint:sha-256 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
a=setup:actpass
a=mid:audio
a=sendrecv
a=rtcp-mux
a=rtpmap:111 opus/48000/2
a=fmtp:111 minptime=10;useinbandfec=1
"""
        }

        try:
            async with self.session.post(
                f"{self.base_url}/webrtc/offer",
                json=mock_offer,
                headers={'Content-Type': 'application/json'}
            ) as response:
                if response.status == 200:
                    answer = await response.json()
                    logger.info("✅ WebRTC offer endpoint working")
                    logger.debug(f"Received answer: {json.dumps(answer, indent=2)}")
                    return True
                else:
                    error_text = await response.text()
                    logger.error(f"❌ WebRTC offer endpoint returned status {response.status}: {error_text}")
                    return False
        except Exception as e:
            logger.error(f"❌ Failed to test WebRTC offer endpoint: {e}")
            return False

    async def diagnose_webrtc_issues(self):
        """Run comprehensive WebRTC diagnostics."""
        logger.info("🔍 Starting WebRTC diagnostics...")

        # Test 1: Server connectivity
        if not await self.test_server_connectivity():
            logger.error("❌ Server connectivity failed - cannot proceed with other tests")
            return

        # Test 2: Configuration endpoint
        config = await self.test_config_endpoint()
        if not config:
            logger.error("❌ Configuration test failed - WebRTC likely won't work")
            return

        # Test 3: WebRTC offer endpoint
        if not await self.test_webrtc_offer_endpoint():
            logger.error("❌ WebRTC offer endpoint test failed")

        # Test 4: Check for common configuration issues
        await self.check_common_issues(config)

        logger.info("🔍 Diagnostics complete!")

    async def check_common_issues(self, config: Optional[Dict]):
        """Check for common WebRTC configuration issues."""
        logger.info("Checking for common issues...")

        if not config:
            logger.error("❌ No configuration available for analysis")
            return

        # Check ICE servers
        rtc_config = config.get('rtc_configuration', {})
        ice_servers = rtc_config.get('iceServers', [])

        if not ice_servers:
            logger.warning("⚠️  No ICE servers configured - this may cause connection issues")
        else:
            has_stun = any('stun:' in server.get('urls', [''])[0] if isinstance(server.get('urls'), list)
                          else 'stun:' in server.get('urls', '')
                          for server in ice_servers)
            has_turn = any('turn:' in server.get('urls', [''])[0] if isinstance(server.get('urls'), list)
                          else 'turn:' in server.get('urls', '')
                          for server in ice_servers)

            if not has_stun:
                logger.warning("⚠️  No STUN servers found - NAT traversal may fail")
            else:
                logger.info("✅ STUN server(s) configured")

            if not has_turn:
                logger.warning("⚠️  No TURN servers found - connections through restrictive firewalls may fail")
            else:
                logger.info("✅ TURN server(s) configured")

    async def test_datachannel_states(self):
        """Provide guidance on DataChannel state issues."""
        logger.info("📋 DataChannel State Troubleshooting Guide:")
        logger.info("   - 'connecting': DataChannel is being established")
        logger.info("   - 'open': DataChannel is ready for data transfer")
        logger.info("   - 'closing': DataChannel is being closed")
        logger.info("   - 'closed': DataChannel is closed")
        logger.info("")
        logger.info("💡 Common issues:")
        logger.info("   1. Trying to send data before channel is 'open'")
        logger.info("   2. Connection failures due to network/firewall issues")
        logger.info("   3. ICE connection failures")
        logger.info("   4. Premature channel closure")
        logger.info("")
        logger.info("🔧 Solutions implemented:")
        logger.info("   - Added readyState checking before sending")
        logger.info("   - Added proper error logging")
        logger.info("   - Added connection state monitoring")

def print_usage():
    """Print usage information."""
    print("""
WebRTC Connection Debugger for UV Projects

Usage: uv run debug_webrtc_connection.py [BASE_URL]

Arguments:
    BASE_URL    Server base URL (default: http://localhost:8080)

Examples:
    uv run debug_webrtc_connection.py
    uv run debug_webrtc_connection.py http://localhost:8080
    uv run debug_webrtc_connection.py https://myserver.com:8443

Alternative usage:
    uv run python debug_webrtc_connection.py [BASE_URL]

This script will:
    1. Test server connectivity
    2. Validate configuration endpoint
    3. Test WebRTC offer/answer exchange
    4. Check for common configuration issues
    5. Provide troubleshooting guidance

NOTE: Make sure your OpenAvatarChat server is running before using this tool!
    """)

async def main():
    """Main debugging function."""
    base_url = "http://localhost:8080"

    if len(sys.argv) > 1:
        if sys.argv[1] in ['-h', '--help', 'help']:
            print_usage()
            return
        base_url = sys.argv[1]

    logger.info(f"🚀 Starting WebRTC debugging for {base_url}")
    logger.info("💡 This is a UV project - make sure to run with 'uv run' command")
    logger.info("🌐 Ensure your OpenAvatarChat server is running before testing")

    async with WebRTCDebugger(base_url) as debugger:
        await debugger.diagnose_webrtc_issues()
        await debugger.test_datachannel_states()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("🛑 Debugging interrupted by user")
    except ImportError as e:
        logger.error(f"📦 Missing dependency: {e}")
        logger.error("💡 Try running: uv sync")
        logger.error("💡 Or install missing packages with: uv add <package_name>")
    except Exception as e:
        logger.error(f"💥 Unexpected error: {e}")
        logger.error("💡 Make sure your OpenAvatarChat server is running")
        logger.error("💡 Check if the base URL is correct")
        raise
