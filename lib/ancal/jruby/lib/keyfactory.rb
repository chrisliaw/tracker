require 'java'
require 'logger'

Dir.entries(File.join(File.dirname(__FILE__),"..","jars")).each do |f|
	if f != "." and f != ".." and File.extname(f) == ".jar"
		require File.join(File.dirname(__FILE__),"..","jars",f)
	end
end

module AnCAL
	module KeyFactory
		GenerateKey = Proc.new do |size,type|
			JCE::GenerateKey.call(size,type.to_s)
		end

		NewKeyPairInstance = Proc.new do 
			kp = java.security.KeyPair.new(nil,nil)
			kp.extend(AnCAL::KeyStore::InputStoreEngine)
			kp
		end

		module JCE
			DEFAULT_JCE_PROVIDER = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new

			GenerateKey = Proc.new do |size, type = "RSA", provider = DEFAULT_JCE_PROVIDER| 
				#logger = params[:logger] || LOG

				# Provider exist to facilitate key generated in the HSM or external providers
				if provider != nil
					#logger.debug "[JCE.KeyPairGenerator] Get #{type} keypair generator with provider #{provider.getName}"
					Java::JavaSecurity::Security::add_provider(provider) 
					keygen = Java::JavaSecurity::KeyPairGenerator::get_instance(type,provider) 
				else
					#logger.debug "[JCE.KeyPairGenerator] Get #{type} keypair generator without provider"
					keygen = Java::JavaSecurity::KeyPairGenerator::get_instance(type) 
				end

				# Method 1 : Reflection
				#keygen.java_send :initialize, [Java::int], size_in_bits
				# Method 2 : using java_method
				keygen_init = keygen.java_method :initialize, [Java::int] 
				#logger.debug "[JCE.KeyPairGenerator] Initialize keygen with size #{keyLength}"
				keygen_init.call size
				kp = keygen.generate_key_pair() 
				kp.extend(AnCAL::KeyStore::OutputStoreEngine)
				#logger.debug "[JCE.KeyPairGenerator] Keypair of #{type} with size #{keyLength} successfully generated"
				kp
			end

		end
	end
end
