require 'java'
require 'logger'

Dir.entries(File.join(File.dirname(__FILE__),"..","jars")).each do |f|
	if f != "." and f != ".." and File.extname(f) == ".jar"
		require File.join(File.dirname(__FILE__),"..","jars",f)
	end
end

module AnCAL
	module KeyStore
		DEFAULT_KEYSTORE_PROVIDER = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new
		module OutputStoreEngine
			def to_pkcs12(pass,keyname,cert_chain,outputStream = nil,prov = DEFAULT_KEYSTORE_PROVIDER)
				#prov = DEFAULT_KEYSTORE_PROVIDER
				Java::JavaSecurity::Security::add_provider(prov) 
				keystore = Java::JavaSecurity::KeyStore::get_instance("pkcs12",prov)
				keystore.load(nil,nil)
				keystore.set_key_entry(keyname,self.getPrivate,pass.to_java.toCharArray,cert_chain.to_java(Java::JavaSecurityCert::Certificate))
				if outputStream != nil
					keystore.store(outputStream,pass.to_java.toCharArray)
					outputStream.flush
				else
					baos = java.io.ByteArrayOutputStream.new
					keystore.store(baos,pass.to_java.toCharArray)
					baos.toByteArray
				end
			end

			def to_jks
				
			end
		end

		module InputStoreEngine
			def from_pkcs12
				puts "from_pkcs12"
			end

			def from_jks
				
			end
		end
	end
end

