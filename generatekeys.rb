
require 'openssl'

private_key = OpenSSL::PKey::RSA.new(2048)
File.open('private.pem', 'w') { |f| f.write(private_key.to_pem) }

public_key = private_key.public_key
File.open('public.pem', 'w') { |f| f.write(public_key.to_pem) }
