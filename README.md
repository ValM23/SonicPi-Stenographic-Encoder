# SonicEncoder: A Proof-of-Concept for Musical Steganography

SonicEncoder is a Proof-of-Concept (PoC) project, written in Ruby, that explores steganography by converting plaintext data into musical note patterns. These patterns can then be rendered into audible music using Sonic Pi, effectively hiding data in plain sight as a piece of music.

## Produced in conjunction with Security Researchers within The Chaos Foundry Sec Div (Thanks, gals. <3) 
- https://twitch.tv/chaosfoundry

## Project Purpose & Security Context

The goal of this project was to research and demonstrate a novel covert channel. In a cybersecurity context, this explores how data might be exfiltrated from a target system in an unconventional format (like a .wav or .mp3 file) to bypass simple data loss prevention (DLP) filters that look for text, documents, or known file headers.

This PoC serves as a tool for security researchers and blue teams to understand and anticipate creative evasion techniques.

## Current Status & Key Features

Status: Proof-of-Concept

Language: Ruby

Core Function: Encodes plaintext strings (e.g., messages, IP addresses) into a series of MIDI-compatible notes.

Encryption: The initial message is encrypted using a public/private key pair before encoding, ensuring the message is not in cleartext within the note data.

Harmonic Filtering: Includes logic to filter notes onto a C-scale. This makes the resulting musical output more harmonic and less suspicious than atonal, random noise.

## Setup & Usage

This project is written in Ruby.

Before use, a public/private key pair must be generated. The generatekeys.rb script is provided for this purpose.

The output text from songitizer.rb is designed to be pasted directly into Sonic Pi to render the musical output.

## Future Development (Roadmap)

The project is currently an encoder only. The logical next steps are:

 - Decoder Implementation: The immediate priority is to build the corresponding decoder. This would involve parsing a .wav or MIDI file, extracting the note data, and using the private key to decrypt the message, converting the music back into the original plaintext.

- Obfuscation & Complexity: Research appending "junk" data—harmonically-correct, but non-message notes—to the output. This would increase the complexity and tonality of the 'song,' making programmatic analysis more difficult.

- P2P Communication: A long-term goal is to explore a P2P framework where two clients could exchange messages as songs, using key verification to authenticate and decode the communications in real-time.

# Disclaimer

This project is intended for academic and security research purposes only. It is a Proof-of-Concept built to explore steganographic techniques from a defensive and research-oriented perspective.
