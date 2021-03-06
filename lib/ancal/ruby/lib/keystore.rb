
require 'openssl'
# Part of AnCAL 
# Inject inside the OpenSSL private key object
module OpenSSL::PKey
	class RSA
		def to_pkcs12(pass,cert,ca_certs=[],name = "")
			if ca_certs != nil and not (ca_certs.kind_of? Array)
				ca_certs = [ca_certs]
			end

			#if name != nil and not name.empty?
			#else
			#	# default name
			#	name = "Generated by AnCAL"	
			#end

			OpenSSL::PKCS12.create(pass,name,self,cert,ca_certs)
		end

		def self.from_pkcs12_url(url,pass)
			File.open(url,"r") do |f|
				@cont = f.read
			end
			from_pkcs12(@cont,pass)
		end

		def self.from_pkcs12(bin,pass)
			keystore = OpenSSL::PKCS12.new(bin,pass)
			OpenSSL::PKey::RSA.new keystore.key
		end

	end
end

