#!/usr/bin/env python3
"""
Standalone WebRTC Test Server for OpenAvatarChat DataChannel Fixes

This is a minimal WebRTC server that focuses on testing the DataChannel
state checking fixes without requiring the full OpenAvatarChat stack.

Usage:
    python webrtc_test_server.py [--port 8080] [--host 0.0.0.0]
"""

import asyncio
import json
import logging
import argparse
import ssl
import os
from typing import Dict, Optional
from aiohttp import web, WSMsgType
from aiohttp.web import Response, Request
import weakref
import uuid
from datetime import datetime

# Try to import aiortc - if not available, provide mock
try:
    from aiortc import RTCPeerConnection, RTCDataChannel, RTCSessionDescription
    from aiortc.contrib.media import MediaPlayer, MediaRelay
    AIORTC_AVAILABLE = True
except ImportError:
    AIORTC_AVAILABLE = False
    print("⚠️  aiortc not available - running in mock mode")

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MockRTCDataChannel:
    """Mock DataChannel for testing when aiortc is not available"""
    def __init__(self):
        self.readyState = 'open'
        self.label = 'test'

    def send(self, data):
        logger.info(f"📤 MOCK: Sending data: {data}")

    def close(self):
        self.readyState = 'closed'

class MockRTCPeerConnection:
    """Mock PeerConnection for testing when aiortc is not available"""
    def __init__(self, configuration=None):
        self.configuration = configuration or {}
        self.localDescription = None
        self.remoteDescription = None

    def createDataChannel(self, label, options=None):
        return MockRTCDataChannel()

    async def createOffer(self):
        return type('Offer', (), {
            'type': 'offer',
            'sdp': 'mock-sdp-offer'
        })()

    async def createAnswer(self):
        return type('Answer', (), {
            'type': 'answer',
            'sdp': 'mock-sdp-answer'
        })()

    async def setLocalDescription(self, desc):
        self.localDescription = desc

    async def setRemoteDescription(self, desc):
        self.remoteDescription = desc

    async def close(self):
        pass

def safe_channel_send(channel, message_data, message_type="message"):
    """
    Safely send message through DataChannel with proper state checking.
    This is our main fix for the DataChannel InvalidStateError issue.

    Args:
        channel: The DataChannel object
        message_data: The data to send (will be JSON stringified if not already string)
        message_type: Type description for logging purposes

    Returns:
        bool: True if message was sent successfully, False otherwise
    """
    if not channel:
        logger.warning(f"❌ Cannot send {message_type}: channel is None")
        return False

    if not hasattr(channel, 'readyState'):
        logger.warning(f"❌ Cannot send {message_type}: channel has no readyState attribute")
        return False

    if channel.readyState != 'open':
        logger.warning(f"❌ Cannot send {message_type}: channel state is '{channel.readyState}', expected 'open'")
        return False

    try:
        if isinstance(message_data, str):
            channel.send(message_data)
        else:
            channel.send(json.dumps(message_data))
        logger.info(f"✅ Successfully sent {message_type}")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send {message_type}: {e}")
        return False

class WebRTCTestServer:
    def __init__(self):
        self.connections: Dict[str, RTCPeerConnection] = {}
        self.data_channels: Dict[str, RTCDataChannel] = {}

    async def handle_index(self, request: Request) -> Response:
        """Serve the enhanced debug page"""
        try:
            with open('webrtc_debug_enhanced.html', 'r') as f:
                content = f.read()
            return Response(text=content, content_type='text/html')
        except FileNotFoundError:
            return Response(text="""
<!DOCTYPE html>
<html>
<head>
    <title>WebRTC Test Server</title>
</head>
<body>
    <h1>🔍 WebRTC DataChannel Test Server</h1>
    <p>✅ Server is running and ready for testing!</p>
    <p>📋 Available endpoints:</p>
    <ul>
        <li><code>/config</code> - Configuration endpoint</li>
        <li><code>/webrtc/offer</code> - WebRTC offer endpoint</li>
        <li><code>/test</code> - DataChannel send test</li>
    </ul>
    <p>💡 The enhanced debug page (webrtc_debug_enhanced.html) was not found.</p>
</body>
</html>
            """, content_type='text/html')

    async def handle_config(self, request: Request) -> Response:
        """Handle configuration requests"""
        config = {
            "rtc_configuration": {
                "iceServers": [
                    {"urls": "stun:stun.l.google.com:19302"},
                    {"urls": "stun:stun1.l.google.com:19302"}
                ],
                "bundlePolicy": "balanced",
                "iceCandidatePoolSize": 10,
                "iceTransportPolicy": "all"
            },
            "server_info": {
                "name": "WebRTC Test Server",
                "version": "1.0.0",
                "datachannel_fixes": "enabled",
                "timestamp": datetime.now().isoformat()
            }
        }

        logger.info("📋 Configuration requested")
        return Response(
            text=json.dumps(config, indent=2),
            content_type='application/json'
        )

    async def handle_webrtc_offer(self, request: Request) -> Response:
        """Handle WebRTC offer requests"""
        try:
            data = await request.json()
            webrtc_id = data.get('webrtc_id', str(uuid.uuid4()))
            offer_sdp = data.get('sdp')
            offer_type = data.get('type')

            logger.info(f"📡 Received WebRTC offer for session {webrtc_id}")

            # Create peer connection
            if AIORTC_AVAILABLE:
                pc = RTCPeerConnection(configuration={
                    "iceServers": [
                        {"urls": "stun:stun.l.google.com:19302"}
                    ]
                })
            else:
                pc = MockRTCPeerConnection()

            self.connections[webrtc_id] = pc

            # Set up data channel handling
            @pc.on("datachannel") if AIORTC_AVAILABLE else lambda: None
            def on_datachannel(channel):
                logger.info(f"📺 DataChannel established: {channel.label}")
                self.data_channels[webrtc_id] = channel

                @channel.on("open")
                def on_open():
                    logger.info(f"✅ DataChannel opened for {webrtc_id}")
                    # Test our safe send function
                    safe_channel_send(
                        channel,
                        {"type": "server_ready", "message": "DataChannel connection established!"},
                        "welcome message"
                    )

                @channel.on("message")
                def on_message(message):
                    logger.info(f"📨 Received message: {message}")
                    try:
                        msg_data = json.loads(message)

                        # Test different message types
                        if msg_data.get('type') == 'chat':
                            # Simulate the original problematic code path
                            response = {
                                "type": "chat_response",
                                "id": msg_data.get('id', str(uuid.uuid4())),
                                "message": f"Echo: {msg_data.get('data', 'No data')}"
                            }
                            safe_channel_send(channel, response, "chat response")

                        elif msg_data.get('type') == 'stop_chat':
                            # Simulate stop handling
                            safe_channel_send(
                                channel,
                                {"type": "chat_stopped", "message": "Chat stopped"},
                                "stop confirmation"
                            )

                        elif msg_data.get('type') == 'test':
                            # Test response
                            safe_channel_send(
                                channel,
                                {
                                    "type": "test_response",
                                    "message": "DataChannel state checking is working!",
                                    "channel_state": channel.readyState,
                                    "timestamp": datetime.now().isoformat()
                                },
                                "test response"
                            )
                        else:
                            # Echo any other message
                            safe_channel_send(
                                channel,
                                {"type": "echo", "original": msg_data},
                                "echo response"
                            )

                    except json.JSONDecodeError:
                        logger.warning(f"⚠️  Received non-JSON message: {message}")
                        safe_channel_send(
                            channel,
                            {"type": "error", "message": "Invalid JSON"},
                            "error response"
                        )

                @channel.on("close")
                def on_close():
                    logger.info(f"📪 DataChannel closed for {webrtc_id}")
                    if webrtc_id in self.data_channels:
                        del self.data_channels[webrtc_id]

            # Handle the offer
            if AIORTC_AVAILABLE:
                offer = RTCSessionDescription(sdp=offer_sdp, type=offer_type)
                await pc.setRemoteDescription(offer)

                # Create answer
                answer = await pc.createAnswer()
                await pc.setLocalDescription(answer)

                response_data = {
                    "type": answer.type,
                    "sdp": answer.sdp
                }
            else:
                # Mock response
                response_data = {
                    "type": "answer",
                    "sdp": "mock-answer-sdp-with-datachannel-support"
                }

            logger.info(f"✅ Created answer for session {webrtc_id}")
            return Response(
                text=json.dumps(response_data),
                content_type='application/json'
            )

        except Exception as e:
            logger.error(f"❌ Error handling WebRTC offer: {e}")
            return Response(
                text=json.dumps({"error": str(e)}),
                content_type='application/json',
                status=500
            )

    async def handle_datachannel_test(self, request: Request) -> Response:
        """Test DataChannel sending functionality"""
        try:
            data = await request.json() if request.content_type == 'application/json' else {}
            webrtc_id = data.get('webrtc_id')
            test_message = data.get('message', 'Test message from server')

            results = []

            if webrtc_id and webrtc_id in self.data_channels:
                # Test specific channel
                channel = self.data_channels[webrtc_id]
                success = safe_channel_send(
                    channel,
                    {"type": "server_test", "message": test_message},
                    f"test message to {webrtc_id}"
                )
                results.append({
                    "webrtc_id": webrtc_id,
                    "success": success,
                    "channel_state": getattr(channel, 'readyState', 'unknown')
                })
            else:
                # Test all channels
                for wid, channel in self.data_channels.items():
                    success = safe_channel_send(
                        channel,
                        {"type": "broadcast_test", "message": test_message},
                        f"broadcast test to {wid}"
                    )
                    results.append({
                        "webrtc_id": wid,
                        "success": success,
                        "channel_state": getattr(channel, 'readyState', 'unknown')
                    })

            return Response(
                text=json.dumps({
                    "test_results": results,
                    "total_channels": len(self.data_channels),
                    "timestamp": datetime.now().isoformat()
                }),
                content_type='application/json'
            )

        except Exception as e:
            logger.error(f"❌ Error in DataChannel test: {e}")
            return Response(
                text=json.dumps({"error": str(e)}),
                content_type='application/json',
                status=500
            )

    async def handle_status(self, request: Request) -> Response:
        """Get server status"""
        status = {
            "server": "WebRTC Test Server",
            "status": "running",
            "connections": len(self.connections),
            "data_channels": len(self.data_channels),
            "aiortc_available": AIORTC_AVAILABLE,
            "datachannel_fixes": "enabled",
            "active_sessions": list(self.data_channels.keys()),
            "timestamp": datetime.now().isoformat()
        }

        return Response(
            text=json.dumps(status, indent=2),
            content_type='application/json'
        )

    def create_app(self) -> web.Application:
        """Create the web application"""
        app = web.Application()

        # Routes
        app.router.add_get('/', self.handle_index)
        app.router.add_get('/config', self.handle_config)
        app.router.add_get('/openavatarchat/initconfig', self.handle_config)  # Compatibility
        app.router.add_post('/webrtc/offer', self.handle_webrtc_offer)
        app.router.add_get('/test', self.handle_datachannel_test)
        app.router.add_post('/test', self.handle_datachannel_test)
        app.router.add_get('/status', self.handle_status)

        # Serve static files
        if os.path.exists('webrtc_debug_enhanced.html'):
            app.router.add_get('/debug', lambda r: web.FileResponse('webrtc_debug_enhanced.html'))

        return app

def main():
    parser = argparse.ArgumentParser(description='WebRTC DataChannel Test Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=8080, help='Port to bind to')
    parser.add_argument('--ssl', action='store_true', help='Enable HTTPS')
    parser.add_argument('--cert', help='SSL certificate file')
    parser.add_argument('--key', help='SSL private key file')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')

    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    # Create server
    server = WebRTCTestServer()
    app = server.create_app()

    # SSL context
    ssl_context = None
    if args.ssl:
        ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        cert_file = args.cert or 'ssl_certs/localhost.crt'
        key_file = args.key or 'ssl_certs/localhost.key'

        try:
            ssl_context.load_cert_chain(cert_file, key_file)
            logger.info(f"🔒 SSL enabled with cert: {cert_file}")
        except Exception as e:
            logger.error(f"❌ Failed to load SSL certificates: {e}")
            logger.info("💡 Continuing without SSL...")
            ssl_context = None

    # Start server
    protocol = 'https' if ssl_context else 'http'
    logger.info(f"🚀 Starting WebRTC Test Server at {protocol}://{args.host}:{args.port}")
    logger.info(f"📋 Configuration endpoint: {protocol}://{args.host}:{args.port}/config")
    logger.info(f"🔍 Debug page: {protocol}://{args.host}:{args.port}/debug")
    logger.info(f"📊 Status endpoint: {protocol}://{args.host}:{args.port}/status")

    if not AIORTC_AVAILABLE:
        logger.warning("⚠️  Running in mock mode - aiortc not available")
        logger.info("💡 Install aiortc with: pip install aiortc")

    web.run_app(app, host=args.host, port=args.port, ssl_context=ssl_context)

if __name__ == '__main__':
    main()
