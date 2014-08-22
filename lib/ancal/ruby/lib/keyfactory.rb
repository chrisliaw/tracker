
require 'openssl'

module OpenSSL
	module PKey
		class RSA
			def keysize_in_bits
				self.n.num_bits
			end
			def keysize_in_bytes
				self.n.num_bytes
			end
		end

		class DSA
			def keysize_in_bits
				self.p.num_bits
			end

			def keysize_in_bytes
				self.p.num_bytes
			end
		end
	end
end

module AnCAL
	module KeyFactory

		GenerateKey = Proc.new do |size,type = :RSA|
			case type
			when :RSA
				RSA::GenerateKey.call(size)
			when :DSA
				DSA::GenerateKey.call(size)
			else
				RSA::GenerateKey.call(size)
			end
		end

		FromP12Url = Proc.new do |url,pass|
			File.open(url,"r") do |f|
				@cont = f.read
			end
			ks = OpenSSL::PKCS12.new(@cont,pass)
			pkey = OpenSSL::PKey::RSA.new ks.key
			cert = ks.certificate
			ca_certs = ks.ca_certs
			[pkey,cert,ca_certs]
		end

		module RSA
			GenerateKey = Proc.new do |keysize|
				OpenSSL::PKey::RSA.generate keysize
			end
		end

		module DSA
			GenerateKey = Proc.new do |keysize|
				OpenSSL::PKey::DSA.generate keysize
			end
		end
	end
end
