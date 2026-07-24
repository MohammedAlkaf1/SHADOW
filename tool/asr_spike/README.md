# ASR spike harness

Standalone CLI to answer the question the product rests on: **can Deepgram
transcribe a real Saudi lecture** (MSA + Hijazi/Saudi dialect + English technical
terms, real room noise)? Not part of the app build — lives under `tool/`.

It streams a recorded audio file to Deepgram using the **exact same transcription
config the app uses** (`lib/custom_code/actions/transcription_mobile.dart`:
`encoding=linear16, sample_rate=16000, channels=1, language=ar, model=nova-2,
smart_format=true, interim_results=true`), then measures word error rate against a
human reference. The only deviation from the app is auth via an `Authorization`
header instead of a URL token — this does not affect transcription.

## Audio format required

| | |
|---|---|
| Container | WAV (RIFF) |
| Codec | PCM signed 16-bit LE (`linear16`) |
| Sample rate | 16000 Hz |
| Channels | 1 (mono) |

Record in any format, then convert:

```
ffmpeg -i lecture.m4a -ac 1 -ar 16000 -sample_fmt s16 -c:a pcm_s16le lecture16k.wav
```

Headerless raw `linear16` (`.pcm`/`.raw`) is also accepted.

## Run

```bash
# 1. Deepgram key (same key the app uses)
export DEEPGRAM_API_KEY=your_key          # PowerShell: $env:DEEPGRAM_API_KEY="your_key"

# 2. Transcribe (streams in real time; writes <audio>.transcript.txt)
dart run tool/asr_spike/asr_spike.dart transcribe lecture16k.wav
#   --fast   stream at ~4x real time
#   --out F  choose output path

# 3. Word error rate (after writing a human reference by hand)
dart run tool/asr_spike/asr_spike.dart wer reference.txt lecture16k.transcript.txt
#   --raw    skip Arabic normalization
```

## How WER is measured

Word-level Levenshtein alignment → `WER = (Substitutions + Deletions + Insertions)
/ reference_words`. Output lists missed, substituted, and inserted words plus an
aligned view. Default normalization (skippable with `--raw`): remove Arabic
diacritics/tatweel, unify alef variants and alef-maqsura→ya and ta-marbuta→ha,
lowercase Latin. Normalization is documented so results are interpretable — a
harsh raw score and a lenient normalized score bracket the true quality.

## Interpreting the result

This is a **provider** decision, not a code bug. If WER on real lecture audio is
poor, the answer is to swap ASR, not to patch the app — which is exactly what the
transcription abstraction is there to allow. Test with a real, noisy recording;
clean studio Arabic will mislead you.
