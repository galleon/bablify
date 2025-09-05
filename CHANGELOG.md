# Changelog

All notable changes to Bablify will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-09-05

### Added
- Initial fork from OpenAvatarChat project
- Complete WebRTC DataChannel InvalidStateError fix
- Enhanced error handling and debugging capabilities
- Mac M3 ARM64 optimizations
- Comprehensive project documentation and roadmap
- Safe DataChannel sending with state validation
- Enhanced frontend debugging tools

### Fixed
- **Critical:** WebRTC DataChannel `InvalidStateError` that prevented reliable communication
- **Critical:** VAD (Voice Activity Detection) blocking subsequent messages after first interaction
- Chat UI visibility issues preventing response display
- Race conditions in WebRTC connection establishment
- Frontend DataChannel send operations without state checking
- Backend DataChannel send operations across multiple FastRTC components

### Changed
- Project name from "OpenAvatarChat" to "Bablify" 
- Project description to emphasize multilingual support
- Disabled LiteAvatar temporarily due to missing Chinese speech models
- Enhanced logging and debugging throughout WebRTC pipeline
- Improved error messages and user feedback

### Technical Details
- Added `safe_channel_send()` function in Python backend
- Added `safeSendDataChannel()` method in Vue.js frontend store  
- Updated 7+ files across backend and frontend for comprehensive DataChannel fixes
- Implemented proper readyState validation before all send operations
- Enhanced debugging with detailed logging and state monitoring

### Architecture
- **Backend:** Python with FastAPI + FastRTC
- **Frontend:** Vue.js 3 + Vite (custom WebRTC interface)  
- **Container:** Docker with Mac M3 ARM64 optimization
- **LLM:** OpenAI GPT-3.5-turbo integration
- **Communication:** WebRTC DataChannels for real-time messaging

### Known Issues
- LiteAvatar system disabled (missing speech_paraformer model for Chinese speech recognition)
- Audio input/output not yet activated
- Some UI text still in Chinese (planned for Phase 1 internationalization)

### Roadmap
- **Phase 1:** Internationalization and multilingual model support
- **Phase 2:** TTS (Text-to-Speech) audio output integration
- **Phase 3:** STT (Speech-to-Text) and VAD audio input integration  
- **Phase 4:** Visual avatar configuration with English language models

---

## Fork Information

This project is a fork of [OpenAvatarChat](https://github.com/HumanAIGC-Engineering/OpenAvatarChat) by HumanAIGC-Engineering team.

**Original Project Credits:** All foundational architecture, design patterns, and core functionality credit goes to the OpenAvatarChat team for creating an excellent base for AI avatar chat systems.

**Fork Enhancements:** This fork focuses on international usability, WebRTC reliability, and multilingual model support.