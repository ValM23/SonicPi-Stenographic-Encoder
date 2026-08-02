# SonicPi Stenographic Encoder

A zero-dependency Ruby tool that encodes RSA-encrypted payloads as MIDI note
sequences — renderable as audio via [Sonic Pi](https://sonic-pi.net/) or a
standard `.mid` file — and decodes them back. Built as a research case for
DLP-evasion-shaped payloads: what happens to detection when exfiltrated data
reads as media instead of bytes?

**Status:** professional demonstration build. Full encode/decode round-trip,
lossless byte mapping, structured payload with optional embedded network
metadata, spec-correct MIDI output, and a dependency-free test suite.

## Why

Most DLP tooling flags exfiltration by inspecting file type, header bytes, or
plaintext patterns. This project asks a narrower question: what happens to
detection if the payload is reshaped into something that reads as media
instead of data? The answer here is a working demonstration — a reference
point for anyone building or testing detections against unconventional
encodings.

## How it works

1. **Payload** — a structured binary message is built: version tag, flags,
   optional IPv4 address, optional TCP port, then the UTF-8 plaintext.
2. **Encryption** — the whole payload is RSA-OAEP encrypted (2048-bit default)
   against a recipient's public key. The note sequence never carries
   cleartext.
3. **Mapping** — each ciphertext byte is split into two nibbles (high/low,
   4 bits each) and mapped to MIDI notes 60..75 (C4..D#6). The mapping is
   fully lossless and invertible — unlike naive `byte % 128` schemes, every
   byte survives the round-trip.
4. **Render** — the note sequence is emitted as runnable Sonic Pi source, or
   written as a standard MIDI file (format 0) that opens in any DAW.

The decoder reverses the whole chain: notes → nibbles → bytes → RSA-OAEP
decrypt → payload parse.

## Requirements

- Ruby 3.x (stdlib only — no gems)
- Sonic Pi (optional — only needed to render the audio; `.mid` output works
  without it)

## Install

```sh
git clone https://github.com/ValM23/SonicPi-Stenographic-Encoder
cd SonicPi-Stenographic-Encoder
# run from the repo root, or add bin/ to your PATH
```

## Usage

```sh
# 1. Generate a keypair
bin/sonic-encoder keygen --private private.pem --public public.pem

# 2. Encode a message -> Sonic Pi source on stdout
bin/sonic-encoder encode -m "payload text" -k public.pem --ip 10.1.2.3 --port 8443

#    ...and/or a .mid file
bin/sonic-encoder encode -m "payload text" -k public.pem --midi payload.mid

# 3. Decode a note sequence back (notes from a file: one per line or CSV)
bin/sonic-encoder decode -f notes.txt -k private.pem

#    or inline
bin/sonic-encoder decode -n "67, 71, 61, 62" -k private.pem

# 4. Round-trip self-test
bin/sonic-encoder demo
```

### Recovering notes from audio

The `.mid` route round-trips exactly. For rendered Sonic Pi audio, capture the
output (or its MIDI if routed through a DAW) and extract the note sequence
before running `decode`. The tool operates on note numbers, not waveforms —
waveform analysis is a natural extension point rather than a built-in.

## Components

```
bin/sonic-encoder           CLI: keygen | encode | decode | demo
lib/sonic_encoder.rb        top-level API
lib/sonic_encoder/
  mapping.rb                lossless byte <-> MIDI-note nibble mapping
  keys.rb                   RSA keypair generation + PEM handling
  payload.rb                structured payload build/parse + RSA-OAEP
  audio.rb                  Sonic Pi source gen + SMF (format 0) writer
test/sonic_encoder_test.rb  zero-dependency test suite (ruby -Ilib test/...)
```

## Tests

```sh
ruby -Ilib test/sonic_encoder_test.rb
```

11 tests: losslessness over all 256 byte values, payload structure, full
encrypt/encode/decode/decrypt round-trips (ASCII + Unicode), error paths, and
MIDI header validity. Zero external dependencies — plain Ruby.

## Limitations

- The `.mid` path is exact; recovering notes from raw rendered audio requires
  capture tooling (DAW/MIDI monitor) — waveform parsing is not built in.
- RSA ciphertext is fixed-size per key (256 bytes for 2048-bit), so message
  length is bounded by key size minus padding overhead and the 8-byte header.
- No P2P key exchange or automated verification — keys are exchanged
  out-of-band, as with any asymmetric scheme.

## Scope

Research and portfolio use — steganographic encoding, public-key handling,
and the size/plausibility tradeoff in disguised channels. Not maintained as
a tool for use against systems without authorization.
