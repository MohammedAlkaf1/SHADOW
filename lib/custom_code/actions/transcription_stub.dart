// Stub implementation — replaced at compile time by platform-specific versions.

Future<void> startPlatformTranscription(
    void Function(String text) onTranscript) async {}

void stopPlatformTranscription() {}

bool get isPlatformSupported => false;
