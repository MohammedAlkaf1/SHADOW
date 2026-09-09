// Stub implementation — replaced at compile time by platform-specific versions.

Future<void> startPlatformTranscription(
    void Function(String text) onTranscript,
    {List<String> courseKeyterms = const []}) async {}

void stopPlatformTranscription() {}

bool get isPlatformSupported => false;
