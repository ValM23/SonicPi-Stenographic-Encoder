# frozen_string_literal: true

require_relative "mapping"

module SonicEncoder
  # Payload construction and RSA encryption of the message.
  #
  # Payload layout (before encryption):
  #   [ 1 byte  ] version tag (0x01)
  #   [ 1 byte  ] options flags (reserved, 0x00)
  #   [ 4 bytes ] optional IPv4 address (0.0.0.0 if absent)
  #   [ 2 bytes ] optional TCP port (big-endian; 0 if absent)
  #   [ N bytes ] UTF-8 plaintext
  #
  # The whole payload is RSA-OAEP encrypted, then the ciphertext bytes are
  # mapped losslessly to MIDI notes.
  module Payload
    VERSION = 0x01

    # Build the structured plaintext payload.
    def self.build(message:, ip: nil, port: nil)
      ip_bytes = ip ? ip.split(".").map(&:to_i) : [0, 0, 0, 0]
      raise ArgumentError, "invalid IPv4: #{ip}" unless ip_bytes.length == 4 && ip_bytes.all? { |o| (0..255).cover?(o) }

      port = port.to_i
      raise ArgumentError, "invalid port: #{port}" unless (0..65_535).cover?(port)

      out = +"".b
      out << VERSION
      out << 0x00
      out << ip_bytes.pack("C4")
      out << [port].pack("n")
      out << message.encode("UTF-8").b
      out
    end

    # Encrypt a message with a recipient's public key.
    # Returns the raw ciphertext bytes.
    def self.encrypt(message:, public_key:, ip: nil, port: nil)
      plain = build(message: message, ip: ip, port: port)
      public_key.public_encrypt(plain, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end

    # Decrypt ciphertext with the recipient's private key.
    # Returns the raw decrypted payload bytes.
    def self.decrypt(ciphertext:, private_key:)
      private_key.private_decrypt(ciphertext, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end

    # Parse a decrypted payload back into its parts.
    # Layout: [1 version][1 flags][4 ip][2 port][message]
    # Returns a Hash with :version, :ip, :port, :message.
    def self.parse(payload)
      raise ArgumentError, "payload too short" if payload.bytesize < 8

      version = payload.getbyte(0)
      ip_bytes = payload.byteslice(2, 4).bytes
      port = payload.byteslice(6, 2).unpack1("n")
      message = payload.byteslice(8..) || ""

      {
        version: version,
        ip: ip_bytes.join("."),
        port: port,
        message: message.force_encoding("UTF-8")
      }
    end
  end
end
