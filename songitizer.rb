require 'openssl'
require 'io/console' # For input, but optional

# Check for public.pem first
unless File.exist?('public.pem')
  puts "Whoops! You need the recipient's public.pem file in this same folder to encrypt stuff. Grab it from them securely and try again."
  exit
end

# Load public key (share this with senders; keep private.pem secret)
public = OpenSSL::PKey::RSA.new(File.read('public.pem'))

puts "Welcome to Chaos Foundry's Music Encryption Service!~\n"
puts "Enter Clear Channel Message:"
message = STDIN.gets.chomp

puts "Enter IP:port (e.g., 192.168.1.1:80) or skip:"
ip_port = STDIN.gets.chomp
ip_bytes = ''
unless ip_port.empty?
  ip, port = ip_port.split('::')
  octets = ip.split('.').map(&:to_i)
  port = port.to_i
  ip_bytes = [octets[0], octets[1], octets[2], octets[3], port].pack('C4n')
end

# Encrypt message
encrypted = public.public_encrypt(message.encode('utf-8'))

# Payload: IP bytes + encrypted
payload = ip_bytes + encrypted

# Bytes to MIDI notes (0-255 -> 48-127 range, safe and audible)
notes = payload.bytes.map { |b| [b % 128 + 48, 127].min }

puts "Want harmonic mapping to C major scale? (y/n):"
harmonic_choice = STDIN.gets.chomp.downcase

if harmonic_choice == 'y'
  major_scale = [60, 62, 64, 65, 67, 69, 71]
  harmonic_notes = []
  payload.bytes.each do |b|  # Switch to original bytes for base-7 encoding
    d2 = b / 49
    d1 = (b % 49) / 7
    d0 = b % 7
    harmonic_notes << major_scale[d2] << major_scale[d1] << major_scale[d0]
  end
  notes = harmonic_notes
end

# Generate Sonic Pi code with start/end drum beats
sonic_code = <<~CODE
  use_bpm 100
  use_synth :organ_tonewheel
  live_loop :secret_jam do
    with_fx :reverb, room: 0.6 do
      sample :bd_tek # Groovy start beat
      sleep 0.5
      play_pattern_timed #{notes}, 0.4, sustain: 0.2
      sleep 0.5
      sample :sn_dolf # Snappy end noise
    end
    sleep 3 # Loop with a breather
  end
CODE

puts "\n#Here is your encrypted tune, copy and paste this into SonicPi to record your message for transmission:\n\n"
puts sonic_code
