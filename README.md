# SonicPi Steganographic Encoder

A proof-of-concept in Ruby that encodes plaintext into MIDI note sequences,
then generates [Sonic Pi](https://sonic-pi.net/) source to render that
sequence as audio. The message survives as a piece of music rather than as
a file with a recognizable header or extension.

## Motivation

Most DLP tooling flags exfiltration by inspecting file type, header bytes,
or plaintext patterns. This project asks a narrower question: what happens
to detection if the payload is reshaped into something that reads as
media instead of data? The answer here is a working demonstration, not a
finished evasion technique — it's meant as a reference point for anyone
building or testing detections against unconventional encodings.

## How it works

The message is first encrypted with RSA (2048-bit) against a recipient's
public key, so the note sequence never carries cleartext. Each byte of
ciphertext maps to a MIDI note number. An optional harmonic mode remaps
the same bytes across the C-major scale instead of the raw note range,
producing a longer sequence that sounds more like a deliberate melody and
less like noise — a direct tradeoff between payload length and how
plausible the output audio is.

`generatekeys.rb` produces the keypair. `songitizer.rb` takes a message
(and optionally an IP:port to prepend) and prints Sonic Pi source ready to
paste and run.

## Limitations

There is no decoder. Recovering the message from rendered audio — parsing
the waveform or a MIDI capture back into note numbers, then RSA-decrypting
— is unimplemented and is the main gap between this and a usable channel.
There's also no obfuscation beyond the harmonic remap, and no mechanism
for two parties to exchange keys or verify each other automatically.

## Possible next steps

- A decoder: recover note data from a WAV or MIDI capture and reverse the
  encoding.
- Padding the note sequence with harmonically valid but non-payload notes,
  to raise the cost of statistical analysis.
- A P2P exchange between two holders of a keypair, with basic verification.

## Scope

Built for research and portfolio purposes — steganographic encoding,
public-key handling, and the size/plausibility tradeoff in disguised
channels. Not maintained as a tool for use against systems without
authorization.
