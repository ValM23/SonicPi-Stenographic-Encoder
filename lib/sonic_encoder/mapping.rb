# frozen_string_literal: true

require "openssl"

module SonicEncoder
  # Lossless byte <-> MIDI-note mapping.
  #
  # MIDI note numbers are 0..127 (7 bits), so a raw byte (0..255) cannot be
  # represented by a single note without losing data. The original PoC used
  # `b % 128 + 48` clamped to 127, which silently corrupted every byte >= 80.
  #
  # This module splits each byte into two nibbles (high/low, 4 bits each) and
  # maps each nibble onto the audible range 60..75 (MIDI C4..D#6). The mapping
  # is fully invertible: decode reads the note, subtracts 60, and recombines
  # high/low nibbles into the original byte.
  module Mapping
    NIBBLE_BASE = 60
    NIBBLE_RANGE = 16

    # Encode a single byte as two MIDI note numbers.
    def self.byte_to_notes(byte)
      high = (byte >> 4) & 0x0F
      low  = byte & 0x0F
      [NIBBLE_BASE + high, NIBBLE_BASE + low]
    end

    # Decode two MIDI note numbers back to a single byte.
    # Raises ArgumentError if either note falls outside the nibble range.
    def self.notes_to_byte(note_high, note_low)
      high = note_high - NIBBLE_BASE
      low  = note_low - NIBBLE_BASE
      unless (0..15).cover?(high) && (0..15).cover?(low)
        raise ArgumentError, "note out of nibble range: #{note_high}, #{note_low}"
      end
      ((high << 4) | low) & 0xFF
    end

    # Encode a whole byte string into a flat array of MIDI notes.
    def self.encode(bytes)
      bytes.bytes.flat_map { |b| byte_to_notes(b) }
    end

    # Decode a flat array of MIDI notes back into a byte string.
    # Length must be even.
    def self.decode(notes)
      raise ArgumentError, "odd note count: #{notes.length}" if notes.length.odd?

      bytes = +"".b
      notes.each_slice(2) do |hi, lo|
        bytes << notes_to_byte(hi, lo)
      end
      bytes
    end
  end
end
