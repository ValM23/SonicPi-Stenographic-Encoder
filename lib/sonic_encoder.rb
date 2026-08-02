# frozen_string_literal: true

require_relative "sonic_encoder/mapping"
require_relative "sonic_encoder/keys"
require_relative "sonic_encoder/payload"
require_relative "sonic_encoder/audio"

# Top-level API for the Sonic Encoder.
#
#   keypair  = SonicEncoder.generate_keypair(private_path:, public_path:)
#   notes    = SonicEncoder.encode(message:, public_key:)
#   decoded  = SonicEncoder.decode(notes:, private_key:)
#
# encode returns the MIDI note sequence; decode reverses it fully, returning
# the original message (and any embedded IP/port metadata).
module SonicEncoder
  # Generate a keypair and write both PEM files. Returns [private_path, public_path].
  def self.generate_keypair(private_path: "private.pem", public_path: "public.pem", bits: 2048)
    Keys.write_pair(private_path: private_path, public_path: public_path, bits: bits)
  end

  # Encode a message into a MIDI note sequence.
  # public_key may be a path to a PEM file or a PEM string.
  def self.encode(message:, public_key:, ip: nil, port: nil)
    key = Keys.load_public(public_key)
    ciphertext = Payload.encrypt(message: message, public_key: key, ip: ip, port: port)
    Mapping.encode(ciphertext)
  end

  # Decode a MIDI note sequence back into the original message.
  # private_key may be a path to a PEM file or a PEM string.
  # Returns a Hash: { message:, ip:, port:, version: }.
  def self.decode(notes:, private_key:)
    key = Keys.load_private(private_key)
    ciphertext = Mapping.decode(notes)
    payload = Payload.decrypt(ciphertext: ciphertext, private_key: key)
    Payload.parse(payload)
  end

  # Render a note sequence to Sonic Pi source.
  def self.sonic_pi(notes, **opts)
    Audio.sonic_pi_source(notes, **opts)
  end

  # Render a note sequence to a standard MIDI file. Returns the path.
  def self.to_midi(notes, path, **opts)
    Audio.write_midi(notes, path, **opts)
  end
end
