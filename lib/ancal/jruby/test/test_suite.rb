
# 1. key generation
require "#{File.join(File.dirname(__FILE__),"test_key_factory")}"
# 2. after got key, generate certificate
require "#{File.join(File.dirname(__FILE__),"test_x509")}"
# 3. after got key and cert, then can test keystore
require "#{File.join(File.dirname(__FILE__),"test_keystore")}"
# 4. got key and cert then can test cipher
require "#{File.join(File.dirname(__FILE__),"test_cipher")}"
# 5. same as 4
require "#{File.join(File.dirname(__FILE__),"test_sign")}"
