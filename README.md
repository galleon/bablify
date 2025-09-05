<h1 style='text-align: center; margin-bottom: 1rem'> 🌐 Bablify </h1>

<p align="center">
<strong>Multilingual AI Avatar Chat System</strong>
</p>

<p align="center">
<em>A fork of <a href="https://github.com/HumanAIGC-Engineering/OpenAvatarChat">OpenAvatarChat</a> - Enhanced for international use with WebRTC fixes and multilingual support</em>
</p>

<p align="center">
<strong>🚀 Real-time AI conversations with text, voice, and visual avatars</strong>
</p>

<p align="center">
📱 <strong>Web-based</strong> | 🔊 <strong>TTS/STT</strong> | 👤 <strong>Visual Avatars</strong> | 🌍 <strong>Multilingual</strong> | 🔒 <strong>Self-hosted</strong>
</p>

## 🙏 Acknowledgments

This project is a fork of the excellent [OpenAvatarChat](https://github.com/HumanAIGC-Engineering/OpenAvatarChat) by the HumanAIGC-Engineering team. We've enhanced it with:
- ✅ **Fixed WebRTC DataChannel issues** for reliable real-time communication
- ✅ **International language support** and model compatibility  
- ✅ **Enhanced error handling** and debugging capabilities
- ✅ **Mac M3 optimizations** for Apple Silicon performance

Original project credits go to the OpenAvatarChat team for creating this amazing foundation.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- OpenAI API key (or compatible LLM API)
- Git with submodules support

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone --recursive https://github.com/galleon/bablify.git
   cd bablify
   ```

2. **Set up your API key:**
   ```bash
   # Copy the environment template
   cp .env.example .env
   
   # Edit .env and add your OpenAI API key:
   # OPENAI_API_KEY=your_actual_openai_api_key_here
   ```

3. **Build and run (Mac M3 optimized):**
   ```bash
   ./build_mac_m3.sh
   ```

4. **Access the application:**
   - Open your browser to: `https://localhost:8282`
   - Accept the self-signed certificate warning
   - Click the subtitle toggle button to show chat interface
   - Start chatting with the AI!

### Configuration Files
- Main config: `config/chat_with_minicpm_mac_m3.yaml`
- Environment variables: `.env` (create from `.env.example`)
- Alternative configs available in `config/` directory

## 🔥 Key Features
- **多模态语言模型：支持多模态语言模型，包括文本、音频、视频等。**
- **模块化设计：使用模块化的设计，可以灵活地替换组件，实现不同功能组合。**


## 📢 Latest Updates

### Changelog

- [2025.08.19] ⭐️⭐️⭐️ 版本 0.5.1发布:
  - LiteAvatar支持单机多session，详见下文LiteAvatar配置部分
  - 增加对 Qwen-Omni多模态模型的支持，使用百炼的Qwen-Omni-Realtime API服务，配置文件参考[配置](#chat_with_qwen_omniyaml)
- [2025.08.12] ⭐️⭐️⭐️ 版本 0.5.0发布:
  - 修改为前后端分离版本，前端仓库添加[OpenAvatarChat-WebUI](https://github.com/HumanAIGC-Engineering/OpenAvatarChat-WebUI),方便自定义前端界面，拓展交互
  - 增加了对 dify 的基础调用方式的支持，目前仅支持了chatflow版本
- [2025.06.12] ⭐️⭐️⭐️ 版本 0.4.1发布:
  - 增加对[MuseTalk](https://github.com/TMElyralab/MuseTalk)数字人的支持，支持自定义形象（底版视频自定义）
  - 50个LiteAvatar新形象发布，丰富各种职业角色，请见[LiteAvatarGallery](https://modelscope.cn/models/HumanAIGC-Engineering/LiteAvatarGallery)
- [2025.04.18] ⭐️⭐️⭐️ 版本 0.3.0发布:
  - 🎉🎉🎉 热烈祝贺[LAM](https://github.com/aigc3d/LAM)论文被SIGGRAPH 2025接收！🎉🎉🎉
  - 增加对[LAM](https://github.com/aigc3d/LAM)数字人 (能够单图秒级打造超写实3D数字人的开源项目) 的支持
  - 增加使用百炼API的tts handler，可以大幅减少对GPU的依赖
  - 增加对微软Edge TTS的支持
  - 现在使用uv进行python的包管理，依赖可以按照配置中所激活的handler进行安装
  - CSS响应式布局更新
- [2025.04.14] ⭐️⭐️⭐️ 版本 0.2.2发布：
  - 100个LiteAvatar新形象发布，请见[LiteAvatarGallery](https://modelscope.cn/models/HumanAIGC-Engineering/LiteAvatarGallery)
  - 默认使用GPU后端运行数字人[lite-avatar](https://github.com/HumanAIGC/lite-avatar)
- [2025.04.07] ⭐️⭐️⭐️ 版本 0.2.1发布： 
  - 增加历史记录支持 
  - 支持文本输入 
  - 启动时不再强制要求摄像头存在 
  - 优化模块化加载方式
- [2025.02.20] ⭐️⭐️⭐️ 版本 0.1.0发布： 
  - 模块化的实时交互对话数字人 
  - 支持MiniCPM-o作为多模态语言模型和云端的 api 两种调用方

### To-Do List

- [ ] Improve documentation and video tutorials
- [ ] Integrate Live2D digital avatars
- [ ] Integrate 3D digital avatars

## Demo

### Online Experience
We have deployed demo services on
<a href="https://www.modelscope.cn/studios/HumanAIGC-Engineering/open-avatar-chat" target="_blank" style="display: inline-block; vertical-align: middle;">
    <img alt="Static Badge" style="height: 10px; margin-right: 1px;" src="./assets/images/modelscope_logo.png">
ModelScope
 </a>
和
<a href="https://huggingface.co/spaces/HumanAIGC-Engineering-Team/open-avatar-chat" target="_blank" style="display: inline-block; vertical-align: middle;">
    🤗
HuggingFace
 </a>
Both platforms offer demo services. The audio processing uses ``SenseVoice + Qwen-VL + CosyVoice``, and you can switch between ``LiteAvatar`` and ``LAM`` digital avatar modes. Welcome to try it out!

### Videos
<table>
  <tr>
    <td align="center">
      <h3>LiteAvatar</h3>
      <video controls src="https://github.com/user-attachments/assets/e2861200-84b0-4c7a-93f0-f46268a0878b"></video>
    </td>
    <td align="center">
      <h3>LAM</h3>
      <video controls src="https://github.com/user-attachments/assets/a72a8c33-39dd-4656-a4a9-b76c5487c711"></video>
    </td>
  </tr>
</table>

## Community

* WeChat Group

<img alt="community_wechat.png" height="200" src="https://github.com/HumanAIGC-Engineering/OpenAvatarChat/blob/main/assets/images/community_wechat.png" width="200"/>

* Official Video Tutorials

We have created a series of introduction videos for this project. Welcome to watch them on [Bilibili](https://www.bilibili.com/video/BV1sv8QzLEC2).
[![Click to watch project demo video](./assets/images/bilibili_video.jpg)](https://www.bilibili.com/video/BV1sv8QzLEC2)

## 🚨 FAQ
For common issues encountered during the project, please refer to [this link](./docs/FAQ.md)

## 📖Table of Contents <!-- omit in toc -->

- [🔥Core Features](#core-features)
- [📢 Latest Updates](#-latest-updates)
  - [Changelog](#changelog)
  - [To-Do List](#to-do-list)
- [Demo](#demo)
  - [Online Experience](#online-experience)
  - [Videos](#videos)
- [Community](#community)
- [🚨 FAQ](#-faq)
- [Overview](#overview)
  - [Introduction](#introduction)
  - [System Requirements](#system-requirements)
  - [Performance Metrics](#performance-metrics)
  - [Component Dependencies](#component-dependencies)
  - [Preset Modes](#preset-modes)
- [🚀Installation and Deployment](#installation-and-deployment)
  - [Configuration Selection](#configuration-selection)
    - [chat\_with\_lam.yaml](#chat_with_lamyaml)
      - [Handlers Used](#handlers-used)
    - [chat\_with\_qwen-omni.yaml](#chat_with_qwen_omniyaml)
    - [chat\_with\_minicpm.yaml](#chat_with_minicpmyaml)
      - [Handlers Used](#handlers-used-1)
    - [chat\_with\_openai\_compatible.yaml](#chat_with_openai_compatibleyaml)
     - [Handlers Used](#handlers-used-2)
    - [chat\_with\_openai\_compatible\_edge\_tts.yaml](#chat_with_openai_compatible_edge_ttsyaml)
     - [Handlers Used](#handlers-used-3)
    - [chat\_with\_openai\_compatible\_bailian\_cosyvoice.yaml](#chat_with_openai_compatible_bailian_cosyvoiceyaml)
     - [Handlers Used](#handlers-used-4)
    - [chat\_with\_openai\_compatible\_bailian\_cosyvoice\_musetalk.yaml](#chat_with_openai_compatible_bailian_cosyvoice_musetalkyaml)
     - [Handlers Used](#handlers-used-5)
  - [Local Execution](#local-execution)
    - [UV Installation](#uv-installation)
    - [Dependency Installation](#dependency-installation)
      - [Install All Dependencies](#install-all-dependencies)
      - [Install Only Required Dependencies](#install-only-required-dependencies)
    - [Run](#run)
  - [Docker Execution](#docker-execution)
- [Handler Dependency Installation Guide](#handler-dependency-installation-guide)
  - [Server-side Rendering RTC Client Handler](#server-side-rendering-rtc-client-handler)
  - [LAM Client-side Rendering Handler](#lam-client-side-rendering-handler)
    - [Avatar Selection](#avatar-selection)
  - [OpenAI Compatible API Language Model Handler](#openai-compatible-api-language-model-handler)
  - [Qwen-Omni Multimodal Language Model Handler](#qwen-omni-multimodal-language-model-handler)
  - [MiniCPM Multimodal Language Model Handler](#minicpm-multimodal-language-model-handler)
    - [Required Models](#required-models)
  - [Bailian CosyVoice Handler](#bailian-cosyvoice-handler)
  - [CosyVoice Local Inference Handler](#cosyvoice-local-inference-handler)
  - [Edge TTS Handler](#edge-tts-handler)
  - [LiteAvatar Digital Human Handler](#liteavatar-digital-human-handler)
    - [Required Models](#required-models-1)
    - [Configuration Parameters](#configuration-parameters)
  - [LAM Digital Human Driver Handler](#lam-digital-human-driver-handler)
    - [Required Models](#required-models-2)
  - [MuseTalk Digital Human Handler](#musetalk-digital-human-handler)
    - [Required Models](#required-models-3)
    - [Configuration Parameters](#configuration-parameters-1)
    - [Run](#run-1)
  - [Dify Chatflow Handler](#dify-chatflow-handler)
- [Related Deployment Requirements](#related-deployment-requirements)
  - [Prepare SSL Certificate](#prepare-ssl-certificate)
  - [TURN Server](#turn-server)
  - [Configuration Guide](#configuration-guide)
- [Community Contributions - Thanks](#community-contributions---thanks)
- [Star History](#star-history)
- [Citation](#citation)
  
  

## Overview

### Introduction

Open Avatar Chat is a modular interactive digital avatar dialogue implementation that can run complete functionality on a single PC. It currently supports MiniCPM-o as a multimodal language model or can use cloud APIs to implement the conventional ASR + LLM + TTS pipeline. The architecture of these two modes is shown in the diagram below. For more preset modes, see [below](#preset-modes).

<p align="center">
<img src="./assets/images/data_flow.svg" />
</p>

### System Requirements
* Python version >=3.11.7, <3.12
* GPU with CUDA support
* The unquantized multimodal language model MiniCPM-o requires more than 20GB of VRAM.
* The digital avatar component can use GPU/CPU for inference. Test device CPU is i9-13980HX, achieving 30FPS with CPU inference.

> [!TIP]
> 
> Using the int4 quantized version of the language model can run on GPUs with less than 10GB of VRAM, but may affect performance due to quantization.
> 
> Using cloud APIs to replace MiniCPM-o and implement conventional ASR + LLM + TTS can greatly reduce hardware requirements. For details, refer to [ASR + LLM + TTS Method](#chat_with_openai_compatible_bailian_cosyvoiceyaml)


### Performance Metrics
In our tests using a PC equipped with an i9-13900KF processor and Nvidia RTX 4090 graphics card, we recorded response latency times. After ten tests, the average latency was approximately 2.2 seconds. The latency is measured from the end of user speech to the beginning of the digital avatar's speech, including RTC bidirectional data transmission time, VAD (Voice Activity Detection) stop delay, and the computational time of the entire pipeline.

### Component Dependencies

| Type       | Open Source Project                    |Github Link|Model Link|
|----------|-------------------------------------|---|---|
| RTC      | HumanAIGC-Engineering/gradio-webrtc |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/HumanAIGC-Engineering/gradio-webrtc)||
| WebUI      | HumanAIGC-Engineering/OpenAvatarChat-WebUI |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/HumanAIGC-Engineering/OpenAvatarChat-WebUI)||
| VAD      | snakers4/silero-vad                 |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/snakers4/silero-vad)||
| LLM      | OpenBMB/MiniCPM-o                   |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/OpenBMB/MiniCPM-o)| [🤗](https://huggingface.co/openbmb/MiniCPM-o-2_6)&nbsp;&nbsp;[<img src="./assets/images/modelscope_logo.png" width="20px"></img>](https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6) |
| LLM-int4 | OpenBMB/MiniCPM-o                   |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/OpenBMB/MiniCPM-o)|[🤗](https://huggingface.co/openbmb/MiniCPM-o-2_6-int4)&nbsp;&nbsp;[<img src="./assets/images/modelscope_logo.png" width="20px"></img>](https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6-int4)|
| Avatar   | HumanAIGC/lite-avatar               |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/HumanAIGC/lite-avatar)||
| TTS      | FunAudioLLM/CosyVoice               |[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/FunAudioLLM/CosyVoice)||
|Avatar|aigc3d/LAM_Audio2Expression|[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/aigc3d/LAM_Audio2Expression)|[🤗](https://huggingface.co/3DAIGC/LAM_audio2exp)|
||facebook/wav2vec2-base-960h||[🤗](https://huggingface.co/facebook/wav2vec2-base-960h)&nbsp;&nbsp;[<img src="./assets/images/modelscope_logo.png" width="20px"></img>](https://modelscope.cn/models/AI-ModelScope/wav2vec2-base-960h)|
|Avatar|TMElyralab/MuseTalk|[<img src="https://img.shields.io/badge/github-white?logo=github&logoColor=black"/>](https://github.com/TMElyralab/MuseTalk)||
|||||


### Preset Modes

| CONFIG Name                                         | ASR |    LLM    |    TTS    | AVATAR|
|----------------------------------------------------|-----|:---------:|:---------:|------------|
| chat_with_lam.yaml                                 |SenseVoice|    API    |API| LAM        |
| chat_with_qwen_omni.yaml                             |Qwen-Omni| Qwen-Omni | Qwen-Omni | lite-avatar |
| chat_with_minicpm.yaml                             |MiniCPM-o| MiniCPM-o | MiniCPM-o | lite-avatar |
| chat_with_openai_compatible.yaml                   |SenseVoice|API|CosyVoice| lite-avatar |
| chat_with_openai_compatible_edge_tts.yaml          |SenseVoice|API|edgetts| lite-avatar |
| chat_with_openai_compatible_bailian_cosyvoice.yaml |SenseVoice|API|API| lite-avatar |
| chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml |SenseVoice|API|API| MuseTalk |
||||||


## 🚀Installation and Deployment

> [!IMPORTANT]
> **【Pre-deployment Warning】Skip this and your digital avatar will 100% fail to work!**
>
> Before you excitedly start deployment, please stop and read this!
> Otherwise, you will likely encounter two major pitfalls: **Interface cannot be accessed** and **Digital avatar stuck in loading forever**.
>
> **To make your digital avatar work, you must complete the following checks:**
>
> 1.  **Confirm module installation**: Check the **relevant module installation methods** required by your chosen mode to ensure nothing is missing.
>
> 2.  **Establish network connectivity**: This is the lifeline for internal/external network communication. **99% of "digital avatar not responding" issues are here!** Please carefully read the **SSL and TURN service** sections in [Related Deployment Requirements](#related-deployment-requirements).
>
>     **Especially, your network environment determines the【Required Configuration】:**
>     *   **① Local access only (`localhost`)**
>         > Simplest option, usually requires no additional configuration. But can only be accessed on the deployment computer, not from other devices (like phones).
>
>     *   **② LAN access (e.g., accessing from phone to computer)**
>         > **SSL 证书开始变得【必要】**！多数浏览器需要 `https://` 安全连接才能授权摄像头/麦克风。没有它，你的数字人无法听和说。
>
>     *   **③ 公网访问 (让任何人都能用)**
>         > **SSL 和 TURN 服务【缺一不可】**！
>         > - **没有合法的 SSL 证书**，浏览器会直接拒绝连接，用户无法打开界面。
>         > - **没有 TURN 服务**，处在不同网络下的用户（比如家里和公司）无法建立视频流连接，连接按钮将一直显示“**等待中**”。

### 选择配置
OpenAvatarChat按照配置文件启动并组织各个模块，可以按照选择的配置现在依赖的模型以及需要准备的ApiKey。项目在config目录下，提供以下预置的配置文件供参考：

#### chat_with_lam.yaml
使用[LAM](https://github.com/aigc3d/LAM)项目生成的gaussion splatting资产进行端侧渲染，语音使用百炼上的Cosyvoice，只有vad和asr运行在本地gpu，对机器性能依赖很轻，可以支持一机多路。
##### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/h5_rendering_client/cllient_handler_lam| [LAM端侧渲染 Client Handler](#lam端侧渲染-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|ASR|asr/sensevoice/asr_handler_sensevoice||
|LLM|llm/openai_compatible/llm_handler/llm_handler_openai_compatible|[OpenAI兼容API的语言模型Handler](#openai兼容api的语言模型handler)
|TTS|tts/bailian_tts/tts_handler_cosyvoice_bailian|[百炼 CosyVoice Handler](#百炼-cosyvoice-handler)|
|Avatar|avatar/lam/avatar_handler_lam_audio2expression|[LAM数字人驱动Handler](#lam数字人驱动handler)|
||||

#### chat_with_qwen_omni.yaml
使用Qwen-Omni进行本地的语音到语音的对话生成，使用了阿里云百炼的线上服务Qwen-Omni-Realtime API。
##### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/rtc_client/client_handler_rtc|[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|LLM|llm/qwen_omni/llm_handler_qwen_omni|[Qwen-Omni多模态语言模型Handler](#Qwen-Omni多模态语言模型Handler)|
|Avatar|avatar/liteavatar/avatar_handler_liteavatar|[LiteAvatar数字人Handler](#liteavatar数字人handler)|
||||

#### chat_with_minicpm.yaml
使用minicpm进行本地的语音到语音的对话生成，对GPU的性能与显存大小有一定要求。
##### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/rtc_client/client_handler_rtc|[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|LLM|llm/minicpm/llm_handler_minicpm|[MiniCPM多模态语言模型Handler](#minicpm多模态语言模型handler)|
|Avatar|avatar/liteavatar/avatar_handler_liteavatar|[LiteAvatar数字人Handler](#liteavatar数字人handler)|
|||| 

#### chat_with_openai_compatible.yaml
该配置使用云端语言模型API，TTS使用cosyvoice，运行在本地。
#### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/rtc_client/client_handler_rtc|[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|ASR|asr/sensevoice/asr_handler_sensevoice||
|LLM|llm/openai_compatible/llm_handler/llm_handler_openai_compatible|[OpenAI兼容API的语言模型Handler](#openai兼容api的语言模型handler)
|TTS|tts/cosyvoice/tts_handler_cosyvoice|[CosyVoice本地推理Handler](#cosyvoice本地推理handler)|
|Avatar|avatar/liteavatar/avatar_handler_liteavatar|[LiteAvatar数字人Handler](#liteavatar数字人handler)|
||||



#### chat_with_openai_compatible_edge_tts.yaml
该配置使用edge tts，效果稍差，但不需要百炼的API Key。
#### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/rtc_client/client_handler_rtc|[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|ASR|asr/sensevoice/asr_handler_sensevoice||
|LLM|llm/openai_compatible/llm_handler/llm_handler_openai_compatible|[OpenAI兼容API的语言模型Handler](#openai兼容api的语言模型handler)
|TTS|tts/edgetts/tts_handler_edgetts|[Edge TTS Handler](#edge-tts-handler)|
|Avatar|avatar/liteavatar/avatar_handler_liteavatar|[LiteAvatar数字人Handler](#liteavatar数字人handler)|
||||

#### chat_with_openai_compatible_bailian_cosyvoice.yaml
语言模型与TTS都使用云端API，2D数字人下对设备要求较低的配置。
#### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/rtc_client/client_handler_rtc|[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|ASR|asr/sensevoice/asr_handler_sensevoice||
|LLM|llm/openai_compatible/llm_handler/llm_handler_openai_compatible|[OpenAI兼容API的语言模型Handler](#openai兼容api的语言模型handler)
|TTS|tts/bailian_tts/tts_handler_cosyvoice_bailian|[百炼 CosyVoice Handler](#百炼-cosyvoice-handler)|
|Avatar|avatar/liteavatar/avatar_handler_liteavatar|[LiteAvatar数字人Handler](#liteavatar数字人handler)|
||||

#### chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml
语言模型与TTS都使用云端API，2D数字人使用MuseTalk进行推理，默认是用GPU进行推理，暂不支持CPU推理。
#### 使用的Handler
|类别|Handler|安装说明|
|---|---|---|
|Client|client/rtc_client/client_handler_rtc|[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)|
|VAD|vad/silerovad/vad_handler/silero||
|ASR|asr/sensevoice/asr_handler_sensevoice||
|LLM|llm/openai_compatible/llm_handler/llm_handler_openai_compatible|[OpenAI兼容API的语言模型Handler](#openai兼容api的语言模型handler)
|TTS|tts/bailian_tts/tts_handler_cosyvoice_bailian|[百炼 CosyVoice Handler](#百炼-cosyvoice-handler)|
|Avatar|avatar/musetalk/avatar_handler_musetalk|[MuseTalk数字人Handler](#musetalk数字人handler)|
||||


### 本地运行


> [!IMPORTANT]
> 本项目子模块以及依赖模型都需要使用git lfs模块，请确认lfs功能已安装
> ```bash
> sudo apt install git-lfs
> git lfs install 
> ```
> 本项目通过git子模块方式引用三方库，运行前需要更新子模块
> ```bash
> git submodule update --init --recursive
> ```
> 强烈建议：国内用户依然使用git clone的方式下载，而不要直接下载zip文件，方便这里的git submodule和git lfs的操作，github访问的问题，可以参考[github访问问题](https://github.com/maxiaof/github-hosts)
> 
> 如果遇到问题欢迎提 [issue](https://github.com/HumanAIGC-Engineering/OpenAvatarChat/issues) 给我们
>
> 本项目的运行依赖CUDA，请确保本机NVIDIA驱动程序支持的CUDA版本>=12.4

#### uv安装

推荐安装[uv](https://docs.astral.sh/uv/)，使用uv进行进行本地环境管理。

> 官方独立安装程序
> ```bash
> # On Windows.
> powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
> # On macOS and Linux.
> curl -LsSf https://astral.sh/uv/install.sh | sh
> ```
> PyPI安装
> ```
> # With pip.
> pip install uv
> # Or pipx.
> pipx install uv
> ```

#### 依赖安装

##### 安装全部依赖
```bash
uv sync --all-packages
```

##### 仅安装所需模式的依赖
```bash
uv venv --python 3.11.11

uv pip install setuptools pip

uv run install.py --uv --config <配置文件的绝对路径>.yaml

./scripts/post_config_install.sh --config <配置文件的绝对路径>.yaml
```

> [!Note]
> `post_config_install.sh` 脚本会将虚拟环境中的NVIDIA CUDA库路径添加到 `ld.so.conf.d` 并更新 `ldconfig` 缓存，以确保系统能正确加载这些动态链接库


#### 运行
```bash
uv run src/demo.py --config <配置文件的绝对路径>.yaml
```


### Docker运行
容器化运行：容器依赖nvidia的容器环境，在准备好支持GPU的docker环境后，运行以下命令即可完成镜像的构建与启动：
```bash
./build_and_run.sh --config <配置文件的相对路径>.yaml
```


## Handler依赖安装说明
### 服务端渲染 RTC Client Handler
暂无特别依赖和需要配置的内容。

### LAM端侧渲染 Client Handler
端侧渲染基于[服务端渲染 RTC Client Handler](#服务端渲染-rtc-client-handler)扩展，支持多路链接，可以通过配置文件选择形象。
#### 形象选择
形象可以通过[LAM](https://github.com/aigc3d/LAM)项目进行训练（LAM对话数字人资产生产流程待完善，敬请期待），本项目中预置了4个范例形象，位于src/handlers/client/h5_rendering_client/lam_samples下。用户可以通过在配置文件中用asset_path字段进行选择，也可以选择自行训练的资产文件。参考配置如下：
```yaml
LamClient:
  module: client/h5_rendering_client/client_handler_lam
  asset_path: "lam_samples/barbara.zip"
  concurrent_limit: 5
```
### OpenAI兼容API的语言模型Handler
本地推理的语言模型要求相对较高，如果你已有一个可调用的 LLM api_key,可以用这种方式启动来体验对话数字人。
可以通过配置文件选择所使用模型、系统prompt、API和API Key。参考配置如下，其中apikey可以被环境变量覆盖。
```yaml
LLMOpenAICompatible: 
  moedl_name: "qwen-plus"
  system_prompt: "你是个AI对话数字人，你要用简短的对话来回答我的问题，并在合理的地方插入标点符号"
  api_url: 'https://dashscope.aliyuncs.com/compatible-mode/v1'
  api_key: 'yourapikey' # default=os.getenv("DASHSCOPE_API_KEY")
```
> [!TIP]
> 系统默认会获取项目当前目录下的.env文件用来获取环境变量。

> [!Note]
> * 代码内部调用方式
> ```python
> client = OpenAI(
>       api_key= self.api_key, 
>       base_url=self.api_url,
>   )
> completion = client.chat.completions.create(
>     model=self.model_name,
>     messages=[
>        self.system_prompt,
>         {'role': 'user', 'content': chat_text}
>     ],
>     stream=True
>     )
> ```
> * LLM默认为百炼api_url + api_key

### Qwen-Omni多模态语言模型Handler
使用百炼的api来接入qwen-omni的能力，当前仅支持manual模式，vad由本地的SileroVad模执行，并且由于manual模式下asr的结果非常差且不可靠返回，因此额外增加了SenseVoice模块仅用于回显对话记录。
完整配置文件可以参考chat_with_qwen_omni.yaml，其中avatar模块可以AvatarMusetalk，LiteAvatar二选一。

### MiniCPM多模态语言模型Handler
#### 依赖模型
* MiniCPM-o-2.6
本项目可以使用MiniCPM-o-2.6作为多模态语言模型为数字人提供对话能力，用户可以按需从[Huggingface](https://huggingface.co/openbmb/MiniCPM-o-2_6)或者[Modelscope](https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6)下载相关模型。建议将模型直接下载到 \<ProjectRoot\>/models/ 默认配置的模型路径指向这里，如果放置与其他位置，需要修改配置文件。scripts目录中有对应模型的下载脚本，可供在linux环境下使用，请在项目根目录下运行脚本：
```bash
scripts/download_MiniCPM-o_2.6.sh
```
```bash
scripts/download_MiniCPM-o_2.6-int4.sh
```

> [!NOTE]
> 本项目支持MiniCPM-o-2.6的原始模型以及int4量化版本，但量化版本需要安装专用分支的AutoGPTQ，相关细节请参考官方的[说明](https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6-int4)

### 百炼 CosyVoice Handler
可以使用百炼提供CosyVoice API调用TTS能力，比本地推理对系统性能要求低，但需要在百炼上开通对应的能力。
参考配置如下：
```
CosyVoice:
  module: tts/bailian_tts/tts_handler_cosyvoice_bailian
  voice: "longxiaocheng"
  model_name: "cosyvoice-v1"
  api_key: 'yourapikey' # default=os.getenv("DASHSCOPE_API_KEY")
```
同[OpenAI兼容API的语言模型Handler]一样，可以将api_key设置在配置中或通过环境变量来覆盖。
> [!TIP]
> 系统默认会获取项目当前目录下的.env文件用来获取环境变量。

### CosyVoice本地推理Handler

> [!WARNING]
> 因为CosyVoice依赖中的pynini包通过PyPI获取时在Windows下编译会出现编译参数不支持的问题。CosyVoice官方目前建议的解决方法是在Windows下用Conda安装
conda-forge中的pynini预编译包。

在Windows下如果使用本地的CosyVoice作为TTS的话，需要结合Conda和UV进行安装。具体依赖安装和运行流程如下：

1. 安装Anaconda或者[Miniconda](https://docs.anaconda.net.cn/miniconda/install/)
```bash
conda create -n openavatarchat python=3.10
conda activate openavatarchat
conda install -c conda-forge pynini==2.1.6
```

2. 设置uv要索引的环境变量为Conda环境
```bash
# cmd
set VIRTUAL_ENV=%CONDA_PREFIX%
# powershell 
$env:VIRTUAL_ENV=$env:CONDA_PREFIX
```

3. 在uv安装依赖和运行时，参数中添加--active，优先使用已激活的虚拟环境
```bash
# 安装依赖
uv sync --active --all-packages
# 仅安装所需依赖
uv run --active install.py --uv --config config/chat_with_openai_compatible.yaml
# 运行cosyvoice 
uv run --active src/demo.py --config config/chat_with_openai_compatible.yaml
```
> [!Note]
> TTS默认为CosyVoice的 `iic/CosyVoice-300M-SFT` + `中文女`，可以通过修改为`其他模型`配合 `ref_audio_path` 和 `ref_audio_text` 进行音色复刻

### Edge TTS Handler
集成微软的edge-tts，使用云端推理，无需申请api key，参考配置如下：
```yaml
Edge_TTS:
  module: tts/edgetts/tts_handler_edgetts
  voice: "zh-CN-XiaoxiaoNeural"
```

### LiteAvatar数字人Handler
集成LiteAvatar算法生产2D数字人对话，目前在modelscope的项目LiteAvatarGallery中提供了100个数字人形象可供使用，详情见[LiteAvatarGallery](https://modelscope.cn/models/HumanAIGC-Engineering/LiteAvatarGallery)。

#### 依赖模型
**使用LiveAvatar之前需要先下载模型参数**, LiteAvatar源码中包含模型下载脚本，为了方便使用，在本项目的`scripts`目录中提供了用于Linux环境的模型下载脚本. 可以在**当前项目的根目录中**调用该脚本:
```bash
bash scripts/download_liteavatar_weights.sh
```

#### 配置参数

LiteAvatar可以运行在CPU或GPU上，如果其他handler都没有对GPU的大开销，建议使用GPU进行推理。
参考配置如下：
```yaml
LiteAvatar:
  module: avatar/liteavatar/avatar_handler_liteavatar
  avatar_name: 20250408/sample_data
  fps: 25
  use_gpu: true
```

#### 多session支持
LiteAvatar支持单机多session，如果要开启，请参考`config/chat_with_openai_compatible_bailian_cosyvoice.yaml`，设置`default.chan_engine.concurrent_limit`即可，通过该参数，在启动时事先声明当前支持的最大并发路数。

需要注意的是，多session对机器的性能要求成倍增加，当LiteAvatar在GPU上运行时，每一路并发大约占用3G显存，如果`concurrent_limit`设置过大，**可能导致显存溢出**，请根据运行机器的配置自行调整并发数量。

### LAM数字人驱动Handler
#### 依赖模型
* facebook/wav2vec2-base-960h [🤗](https://huggingface.co/facebook/wav2vec2-base-960h) [<img src="./assets/images/modelscope_logo.png" width="20px"></img>](https://modelscope.cn/models/AI-ModelScope/wav2vec2-base-960h)
  * 从huggingface下载, 确保lfs已安装，使当前路径位于项目根目录，执行：
  ```
  git clone --depth 1 https://huggingface.co/facebook/wav2vec2-base-960h ./models/wav2vec2-base-960h
  ```
  * 从modelscope下载, 确保lfs已安装，使当前路径位于项目根目录，执行：
  ```
  git clone --depth 1 https://www.modelscope.cn/AI-ModelScope/wav2vec2-base-960h.git ./models/wav2vec2-base-960h
  ```
* LAM_audio2exp [🤗](https://huggingface.co/3DAIGC/LAM_audio2exp)
  * 从huggingface下载, 确保lfs已安装，使当前路径位于项目根目录，执行：
  ```
  wget https://huggingface.co/3DAIGC/LAM_audio2exp/resolve/main/LAM_audio2exp_streaming.tar -P ./models/LAM_audio2exp/
  tar -xzvf ./models/LAM_audio2exp/LAM_audio2exp_streaming.tar -C ./models/LAM_audio2exp && rm ./models/LAM_audio2exp/LAM_audio2exp_streaming.tar
  ```
  * 国内用户可以从oss地址下载, 使当前路径位于项目根目录，执行：
  ```
  wget https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LAM/LAM_audio2exp_streaming.tar -P ./models/LAM_audio2exp/
  tar -xzvf ./models/LAM_audio2exp/LAM_audio2exp_streaming.tar -C ./models/LAM_audio2exp && rm ./models/LAM_audio2exp/LAM_audio2exp_streaming.tar
  ```

### MuseTalk数字人Handler
项目目前集成了最新的MuseTalk 1.5，之前的版本未做测试，当前版本支持自定义形象，可以通过修改avatar_video_path进行选择。

#### 依赖模型
* MuseTalk源码中包含模型下载脚本，但是为了保持目录结构一致，对下载脚本做了修改，修改后的脚本在scripts目录下，可在linux环境下使用。MuseTalk原始代码中使用了相对路径进行加载，虽然进行了适配和修改，但是部分代码无法以输入参数进行设置，所以不要修改模型的下载位置，并在项目根目录下运行脚本：
```
bash scripts/download_musetalk_weights.sh
```

#### 配置参数
* 形象选择：MuseTalk源码中包括两个默认的形象，可以通过修改avatar_video_path参数来选择，系统第一次加载会做数据准备，第二次进入时会直接加载，也可以通过修改force_create_avatar参数来强制每次加载重新生成，avatar_model_dir参数可以指定保存avatar数据的目录，默认在models/musetalk/avatar_model，如无特殊需求无需修改。
* 帧率：虽然按照MuseTalk的文档中的说明可以在V100下做到30fps，但是本项目参考realtime_inference.py中进行适配还未能达到预期，建议fps设为20，实际测试也可以根据GPU性能进行调整。如果测试log中发现warning：“[IDLE_FRAME] Inserted idle during speaking”，说明实际推理时帧率低于设定的fps。
* batch_size：可通过增加batch_size来提高推理的效率，但是batch_size过大会影响系统的首帧响应速度。 batch_size最小为2，如果设置1，log中会出现Error：`[IDLE_FRAME]1 validation error for AvatarMuseTalkConfig，batch_size - Input should be greater than or equal to 2 [type=greater_than_equal, input_value=1, input_type=int]` 

```yaml
Avatar_MuseTalk:
  module: avatar/musetalk/avatar_handler_musetalk
  fps: 20  # Video frame rate
  batch_size: 2  # Batch processing frame count, must be greater than 2
  avatar_video_path: "src/handlers/avatar/musetalk/MuseTalk/data/video/sun.mp4"  # Initialization video path
  avatar_model_dir: "models/musetalk/avatar_model"  # Default avatar model directory
  force_create_avatar: false  # Whether to force regenerate digital human data
  debug: false  # Whether to enable debug mode
  ... # 其他参数可参考 AvatarMuseTalkConfig 源码
```

#### 数字人模型下载工具
通过设置avatar_video_path可以自定义数字人的底版视频，为了方便没有数字人素材的用户进行尝试，我们提供了一个小工具来让Musetalk的用户可以使用Liteavatar中提供的数字人素材。 脚本文件为`scripts/download_avatar_model.py`，模型的列表需要在[LiteAvatarGallery](https://modelscope.cn/models/HumanAIGC-Engineering/LiteAvatarGallery)查看 。

**使用方法：**

```bash
# 1. 查看帮助信息
python scripts/download_avatar_model.py --help

# 2. 下载指定的数字人模型
python scripts/download_avatar_model.py -m "20250612/P1rcvIW8H6kvcYWNkEnBWPfg"

# 3. 查看已下载的模型列表
python scripts/download_avatar_model.py -d

# 输出示例：
# 已下载模型列表:
# avatar_name（for LiteAvatar config）    avatar_video_path（for Musetalk config）
# --------------------------------------------------------------------------------
# 20250612/P1rcvIW8H6kvcYWNkEnBWPfg       resource/avatar/liteavatar/20250612/P1rcvIW8H6kvcYWNkEnBWPfg/bg_video_silence.mp4

```


#### 运行

* Docker

```
./build_and_run.sh --config config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml
```

* 本地运行

本地安装依赖的命令顺序如下：
```bash
uv venv --python 3.11.11

./scripts/pre_config_install.sh --config config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml

uv run install.py --uv --config config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml

./scripts/post_config_install.sh --config config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml
```

需要注意的是，uv默认安装的mmcv在实际运行时可能会报错“No module named ‘mmcv._ext’”参考[MMCV-FAQ](https://mmcv.readthedocs.io/en/latest/faq.html)，解决方法是：
```bash
uv pip uninstall mmcv
uv pip install mmcv==2.2.0 -f https://download.openmmlab.com/mmcv/dist/cu121/torch2.4/index.html --trusted-host download.openmmlab.com
```

MuseTalk源码中第一次启动默认会下载一个模型s3fd-619a316812.pth，该模型目前已集成在下载脚本中。在Docker启动时已经做了映射处理。但在本地运行时，需要再手动进行一次映射。

```
# linux
ln -s $(pwd)/models/musetalk/s3fd-619a316812/* ~/.cache/torch/hub/checkpoints/
```


启动程序可以使用：
```bash
uv run src/demo.py --config config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml
```


### Dify Chatflow Handler 
项目目前集成了Dify的Chatflow，用户可以在Dify中创建一个Chatflow，将生成的Chatflow应用的 api_url 以及 api_key 填入后，即可使用Dify的Chatflow进行对话。
```yaml
 Dify:
      enabled: True
      module: llm/dify/llm_handler_dify
      enable_video_input: False # 是否允许摄像头输入，确保应用支持视觉，并接受 files 输入
      api_key: '' #your dify api key
      api_url: 'http://localhost/v1' # your dify api url
 
```

## 相关部署需求
### 准备ssl证书
由于本项目使用rtc作为视音频传输的通道，用户如果需要从localhost以外的地方连接服务的话，需要准备ssl证书以开启https，默认配置会读取ssl_certs目录下的localhost.crt和localhost.key，用户可以相应修改配置来使用自己的证书。我们也在scripts目录下提供了生成自签名证书的脚本。需要在项目根目录下运行脚本以使生成的证书被放到默认位置。
```bash
scripts/create_ssl_certs.sh
```

### TURN Server
如果点击开始对话后，出现一直等待中的情况，可能你的部署环境存在NAT穿透方面的问题（如部署在云上机器等），需要进行数据中继。在Linux环境下，可以使用coturn来架设TURN服务。可参考以下操作在同一机器上安装、启动并配置使用coturn：
* 运行安装脚本
```console
$ chmod 777 scripts/setup_coturn.sh
# scripts/setup_coturn.sh
```
* 修改config配置文件，添加以下配置后启动服务。
```yaml
default:
  chat_engine:
    handler_configs:
      RtcClient: #若使用Lam，则此项配置为LamClient
        turn_config:
          turn_provider: "turn_server"
          urls: ["turn:your-turn-server.com:3478", "turns:your-turn-server.com:5349"]
          username: "your-username"
          credential: "your-credential"
```
* 确保防火墙（包括云上机器安全组等策略）开放coturn所需端口

### 配置说明
程序默认启动时，会读取 **<project_root>/configs/chat_with_minicpm.yaml** 中的配置，用户也可以在启动命令后加上--config参数来选择从其他配置文件启动。
```bash
uv run src/demo.py --config <配置文件的绝对路径>.yaml
```

可配置的参数列表：

|参数|默认值|说明|
|---|---|---|
|log.log_level|INFO|程序的日志级别。|
|service.host|0.0.0.0|Gradio服务的监听地址。|
|service.port|8282|Gradio服务的监听端口。|
|service.cert_file|ssl_certs/localhost.crt|SSL证书中的证书文件，如果cert_file和cert_key指向的文件都能正确读取，服务将会使用https。|
|service.cert_key|ssl_certs/localhost.key|SSL证书中的证书文件，如果cert_file和cert_key指向的文件都能正确读取，服务将会使用https。|
|chat_engine.model_root|models|模型的根目录。|
|chat_engine.handler_configs|N/A|由各Handler提供的可配置项。|

目前已实现的Handler提供如下的可配置参数：
* VAD

|参数|默认值|说明|
|---|---|---|
|SileraVad.speaking_threshold|0.5|判定输入音频为语音的阈值。|
|SileraVad.start_delay|2048|当模型输出概率持续大于阈值超过这个时间后，将起始超过阈值的时刻认定为说话的开始。以音频采样数为单位。|
|SileraVad.end_delay|2048|当模型输出的概率持续小于阈值超过这个时间后，判定说话内容结束。以音频采样数为单位。|
|SileraVad.buffer_look_back|1024|当使用较高阈值时，语音的起始部分往往有所残缺，该配置在语音的起始点往前回溯一小段时间，避免丢失语音，以音频采样数为单位。|
|SileraVad.speech_padding|512|返回的音频会在起始与结束两端加上这个长度的静音音频，已采样数为单位。|

* 语言模型

| 参数                             | 默认值           | 说明                                                                                 |
|--------------------------------|---------------|------------------------------------------------------------------------------------|
| S2S_MiniCPM.model_name         | MiniCPM-o-2_6 | 该参数用于选择使用的语言模型，可选"MiniCPM-o-2_6" 或者 "MiniCPM-o-2_6-int4"，需要确保model目录下实际模型的目录名与此一致。 |
| S2S_MiniCPM.voice_prompt       |               | MiniCPM-o的voice prompt                                                             |
| S2S_MiniCPM.assistant_prompt   |               | MiniCPM-o的assistant prompt                                                         |
| S2S_MiniCPM.enable_video_input | False         | 设置是否开启视频输入，**开启视频输入时，显存占用会明显增加，非量化模型再24G显存下可能会oom**                                |
| S2S_MiniCPM.skip_video_frame   | -1            | 控制开启视频输入时，输入视频帧的频率。-1表示仅每秒输入最后的一帧，0表示输入所有帧，大于0的值表示每一帧后会有这个数量的图像帧被跳过。               |

* ASR funasr模型

|参数|默认值|说明|
|---|---|---|
|ASR_Funasr.model_name|iic/SenseVoiceSmall|该参数用于选择funasr 下的[模型](https://github.com/modelscope/FunASR)，会自动下载模型，若需使用本地模型需改为绝对路径|

* LLM纯文本模型

|参数|默认值|说明|
|---|---|---|
|LLMOpenAICompatible.model_name|qwen-plus|测试环境使用的百炼api,免费额度可以从[百炼](https://bailian.console.aliyun.com/#/home)获取|
|LLMOpenAICompatible.system_prompt||默认系统prompt|
|LLMOpenAICompatible.api_url||模型api_url|
|LLMOpenAICompatible.api_key||模型api_key|

* TTS CosyVoice模型

|参数|默认值|说明|
|---|---|---|
|TTS_CosyVoice.api_url||自己利用其他机器部署cosyvocie server时需填|
|TTS_CosyVoice.model_name||可参考[CosyVoice](https://github.com/FunAudioLLM/CosyVoice)|
|TTS_CosyVoice.spk_id|中文女|使用官方sft 比如'中文女'|'中文男'，和ref_audio_path互斥|
|TTS_CosyVoice.ref_audio_path||参考音频的绝对路径，和spk_id 互斥，记得更换可参考音色的模型|
|TTS_CosyVoice.ref_audio_text||参考音频的文本内容|
|TTS_CosyVoice.sample_rate|24000|输出音频采样率|

* LiteAvatar数字人

|参数|默认值|说明|
|---|---|---|
|LiteAvatar.avatar_name|sample_data|数字人数据名，目前在modelscope的项目LiteAvatarGallery中提供了100个数字人形象可供使用，详情见[LiteAvatarGallery](https://modelscope.cn/models/HumanAIGC-Engineering/LiteAvatarGallery)。|
|LiteAvatar.fps|25|数字人的运行帧率，在性能较好的CPU上，可以设置为30FPS|
|LiteAvatar.enable_fast_mode|False|低延迟模式，打开后可以减低回答的延迟，但在性能不足的情况下，可能会在回答的开始产生语音卡顿。|
|LiteAvatar.use_gpu|True|LiteAvatar算法是否使用GPU，目前使用CUDA后端|

> [!IMPORTANT]
> 所有配置中的路径参数都可以使用绝对路径，或者相对于项目根目录的相对路径。

## Community Contributions - Thanks

- 感谢社区热心同学“十字鱼”在B站上发布的一键安装包视频，并提供了下载（解压码在视频简介里面有,仔细找找）[一键包](https://www.bilibili.com/video/BV1V1oLYmEu3/?vd_source=29463f5b63a3510553325ba70f325293)
- 感谢社区热心同学“W&H”提供的夸克一键包[windows版本:提取码a79V](https://pan.quark.cn/s/237177126010) 和 [linux 版本:提取码：E8Kq](https://pan.quark.cn/s/b7fcdc157586)
- 感谢社区热心同学“W&H”提供的源码zip[夸克网盘:提取码 9iNy](https://pan.quark.cn/s/9e6156cafacd) 和 [百度云盘:提取码：xrxr](https://pan.baidu.com/s/16-0OBtSD5cBz2gJDJORW7w)


## Star History
![](https://api.star-history.com/svg?repos=HumanAIGC-Engineering/OpenAvatarChat&type=Date)

## Citation

如果您在您的研究/项目中感到 OpenAvatarChat 为您提供了帮助，期待您能给一个 Star⭐和引用✏️

```
@software{avatarchat2025,
  author = {Gang Cheng, Tao Chen, Feng Wang, Binchao Huang, Hui Xu, Guanqiao He, Yi Lu, Shengyin Tan},
  title = {OpenAvatarChat},
  year = {2025},
  publisher = {GitHub},
  url = {https://github.com/HumanAIGC-Engineering/OpenAvatarChat}
}
```
