# frozen_string_literal: true

require "openssl"

module SonicEncoder
  # RSA keypair generation and PEM file handling.
  module Keys
    DEFAULT_BITS = 2048

    # Generate a fresh RSA keypair.
    def self.generate(bits: DEFAULT_BITS)
      OpenSSL::PKey::RSA.new(bits)
    end

    # Write both halves of a keypair to disk (0600 on the private key).
    # Returns the file paths written.
    def self.write_pair(private_path:, public_path:, bits: DEFAULT_BITS)
      key = generate(bits: bits)

      File.write(private_path, key.to_pem)
      File.chmod(0o600, private_path)

      File.write(public_path, key.public_key.to_pem)
      File.chmod(0o644, public_path)

      [private_path, public_path]
    end

    # Load a public key from a PEM file path or PEM string.
    def self.load_public(source)
      pem = File.file?(source) ? File.read(source) : source
      OpenSSL::PKey::RSA.new(pem).public_key
    end

    # Load a private key from a PEM file path or PEM string.
    def self.load_private(source)
      pem = File.file?(source) ? File.read(source) : source
      OpenSSL::PKey::RSA.new(pem)
    end
  end
end
