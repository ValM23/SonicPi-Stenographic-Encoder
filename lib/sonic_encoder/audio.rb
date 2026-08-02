# frozen_string_literal: true

require_relative "mapping"
require_relative "payload"

module SonicEncoder
  # Sonic Pi source generation and MIDI-file rendering of note sequences.
  module Audio
    # Generate Sonic Pi source that renders a note sequence as a track.
    # Returns a String of runnable Sonic Pi code.
    def self.sonic_pi_source(notes, bpm: 100, synth: :organ_tonewheel, drums: true)
      note_list = notes.join(", ")
      drums_block = drums ? "        sample :bd_tek\n        sleep 0.5\n" : ""

      <<~CODE
        use_bpm #{bpm}
        use_synth :#{synth}
        live_loop :sonic_encoder do
          with_fx :reverb, room: 0.6 do
        #{drums_block}        play_pattern_timed [#{note_list}], 0.4, sustain: 0.2
            sleep 0.5
            sample :sn_dolf
          end
          sleep 3
        end
      CODE
    end

    # Encode a non-negative integer as a MIDI variable-length quantity.
    def self.vlq(value)
      bytes = [value & 0x7F]
      value >>= 7
      while value.positive?
        bytes.unshift((value & 0x7F) | 0x80)
        value >>= 7
      end
      bytes.pack("C*")
    end

    # Write a standard MIDI file (format 0) from a note sequence.
    # Returns the path written.
    #
    # Single track, note-on/note-off pairs with proper delta-times,
    # 4/4 time, quarter-note = 120. Opens in any DAW or SMF reader.
    def self.write_midi(notes, path, duration: 0.4)
      File.open(path, "wb") do |f|
        f.write("MThd")
        f.write([6, 0, 1, 480].pack("Nnnn")) # chunk len 6: format 0, 1 track, 480 ppq

        track = +""
        tick = (duration * 480).round
        velocity = 90

        notes.each do |note|
          # note-on immediately after previous event (delta 0), then
          # note-off after `tick` ticks — both deltas relative to the
          # previous event, per SMF spec.
          track << vlq(0) << [0x90, note, velocity].pack("C3")
          track << vlq(tick) << [0x80, note, 0].pack("C3")
        end
        # End-of-track meta event
        track << [0x00, 0xFF, 0x2F, 0x00].pack("C4")

        f.write("MTrk")
        f.write([track.bytesize].pack("N"))
        f.write(track)
      end
      path
    end
  end
end
