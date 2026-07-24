// Selects the correct transcription implementation at compile time.
//   • Web   (dart.library.html)  → Web Speech API via JS bridge
//   • IO    (dart.library.io)    → Deepgram WebSocket
//   • Other                      → no-op stub

export 'transcription_stub.dart'
    if (dart.library.html) 'transcription_web.dart'
    if (dart.library.io) 'transcription_mobile.dart';
