
require 'minitest/autorun'
require "#{File.join(File.dirname(__FILE__),"..","ancal_jruby")}"

class TestKeypair < MiniTest::Test
	def test_rsa
		[1024,2048,4096].each do |i|
			puts "Generating RSA #{i} bits key"
			start = Time.now
			pkey = AnCAL::KeyFactory::GenerateKey.call(i,:RSA)
		  endTime = Time.now
			puts "Generating RSA keysize #{i} bits took #{(endTime-start)*1000} ms"
			#assert_equal(pkey.class,OpenSSL::PKey::RSA)
			#assert_equal(pkey.keysize_in_bits,i)
		end
	end

	def test_dsa
		[512,1024].each do |i|
			puts "Generating DSA #{i} bits key"
			start = Time.now
			pkey = AnCAL::KeyFactory::GenerateKey.call(i,:DSA)
		  endTime = Time.now
			puts "Generating DSA keysize #{i} bits took #{(endTime-start)*1000} ms"
			#assert_equal(pkey.class,OpenSSL::PKey::DSA)
			#assert_equal(pkey.keysize_in_bits,i)
		end
	end
end
