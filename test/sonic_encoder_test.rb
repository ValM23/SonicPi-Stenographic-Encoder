# frozen_string_literal: true

# Zero-dependency test harness — runs with plain Ruby, no gems required.
# Usage: ruby -Ilib test/sonic_encoder_test.rb

require "tmpdir"
require_relative "../lib/sonic_encoder"

$tests = 0
$failures = 0

def test(name)
  $tests += 1
  yield
  puts "ok   - #{name}"
rescue StandardError => e
  $failures += 1
  puts "FAIL - #{name}: #{e.class}: #{e.message}"
  puts "       #{e.backtrace.first(3).join("\n       ")}"
end

def assert(cond, msg = "assertion failed")
  raise msg unless cond
end

def assert_equal(expected, actual, msg = nil)
  raise "#{msg || "expected #{expected.inspect}"}, got #{actual.inspect}" unless expected == actual
end

def assert_raises(klass)
  yield
  raise "expected #{klass} to be raised, nothing raised"
rescue klass
  nil
end

# --- Mapping: losslessness and range ---

test "byte<->note mapping is lossless for all 256 values" do
  256.times do |b|
    hi, lo = SonicEncoder::Mapping.byte_to_notes(b)
    assert_equal b, SonicEncoder::Mapping.notes_to_byte(hi, lo), "byte #{b}"
  end
end

test "encode/decode round-trips a full byte range" do
  bytes = (0..255).to_a.pack("C*") * 4
  notes = SonicEncoder::Mapping.encode(bytes)
  assert_equal bytes, SonicEncoder::Mapping.decode(notes)
end

test "all notes land in the audible nibble range" do
  notes = SonicEncoder::Mapping.encode("Hello, world!")
  assert notes.all? { |n| (60..75).cover?(n) }, "notes out of range: #{notes}"
end

test "odd note count raises" do
  assert_raises(ArgumentError) { SonicEncoder::Mapping.decode([60, 62, 64]) }
end

test "out-of-range note raises" do
  assert_raises(ArgumentError) { SonicEncoder::Mapping.notes_to_byte(127, 60) }
end

# --- Payload structure ---

test "payload round-trips with ip and port" do
  raw = SonicEncoder::Payload.build(message: "secret", ip: "10.0.0.7", port: 443)
  parsed = SonicEncoder::Payload.parse(raw)
  assert_equal "secret", parsed[:message]
  assert_equal "10.0.0.7", parsed[:ip]
  assert_equal 443, parsed[:port]
  assert_equal 0x01, parsed[:version]
end

test "payload round-trips without ip or port" do
  raw = SonicEncoder::Payload.build(message: "plain")
  parsed = SonicEncoder::Payload.parse(raw)
  assert_equal "0.0.0.0", parsed[:ip]
  assert_equal 0, parsed[:port]
  assert_equal "plain", parsed[:message]
end

test "invalid ip raises" do
  assert_raises(ArgumentError) { SonicEncoder::Payload.build(message: "x", ip: "999.1.1.1") }
end

# --- Full round-trip through RSA ---

test "full encode/decode round-trip with metadata" do
  Dir.mktmpdir do |dir|
    priv = File.join(dir, "private.pem")
    pub  = File.join(dir, "public.pem")
    SonicEncoder.generate_keypair(private_path: priv, public_path: pub)

    message = "The quick brown fox jumps over the lazy dog — 12345!?"
    notes = SonicEncoder.encode(message: message, public_key: pub, ip: "192.168.1.42", port: 8443)
    result = SonicEncoder.decode(notes: notes, private_key: priv)

    assert_equal message, result[:message]
    assert_equal "192.168.1.42", result[:ip]
    assert_equal 8443, result[:port]
  end
end

test "unicode survives the round-trip" do
  Dir.mktmpdir do |dir|
    priv = File.join(dir, "private.pem")
    pub  = File.join(dir, "public.pem")
    SonicEncoder.generate_keypair(private_path: priv, public_path: pub)

    message = "Pax Chaosica et Gloria Infinitum — 平和 — 🦀"
    notes = SonicEncoder.encode(message: message, public_key: pub)
    result = SonicEncoder.decode(notes: notes, private_key: priv)

    assert_equal message, result[:message]
  end
end

test "midi file writes a valid MThd header" do
  Dir.mktmpdir do |dir|
    priv = File.join(dir, "private.pem")
    pub  = File.join(dir, "public.pem")
    SonicEncoder.generate_keypair(private_path: priv, public_path: pub)

    message = "midi file check"
    notes = SonicEncoder.encode(message: message, public_key: pub)
    midi_path = File.join(dir, "out.mid")
    SonicEncoder.to_midi(notes, midi_path)

    assert File.exist?(midi_path)
    assert_equal "MThd", File.binread(midi_path, 4)
  end
end

# --- Report ---

puts
if $failures.zero?
  puts "#{$tests} tests, 0 failures — ALL PASS"
  exit 0
else
  puts "#{$tests} tests, #{$failures} failures"
  exit 1
end
