iOS IDVoiceGPT
===========================================

**The application code is compatible with VoiceSDK 3.12.0.**

This application is intended to demonstrate IDVoice® integration with ChatGPT voice controls to authenticate users while they’re speaking to the chatbot.

The solution applies frictionless voice biometrics to secure access to a speech-enabled ChatGPT chat session. As applications for verbal chatbots proliferate, securing access from unauthorized users is becoming an increasingly common requirement. IDVoice performs speaker verification in the background while the user is speaking, avoiding added friction for authorized users.

**All source code contains commentary that should help developers.**

Please refer to [IDVoice quick start guide](https://docs.idrnd.net/voice/#idvoice-speaker-verification), [IDLive quick start guide](https://docs.idrnd.net/voice/#idlive-voice-anti-spoofing) in order to get more detailed information and best practicies for the listed capabilities.

Developer tips
--------------

- This repository does not contain VoiceSDK distribution itself. Please copy libs/VoiceSdk.framework and the contents of init_data folder from the IDVoice + IDLive iOS package received from ID R&D to the VoiceSDK/ folder in order to be able to build and run the application. You can see/modify Initialization paths in `SpeechProcessor.swift`  file.

- Paste your OpenAI API key to `APIKey.swift`.
- Paste your VoiceSDK License key to `LicenseManager.swift`.
- See `SpeechProcessor.swift` for voice processing with speech analysis, recording and buffering code.
