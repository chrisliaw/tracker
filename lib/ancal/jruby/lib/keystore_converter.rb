
require "#{File.join(File.dirname(__FILE__),"key_factory")}"
require 'logger'

module KeystoreConverter

	class KeystoreConverterException < Exception; end
	LOG = Logger.new('keystoreconverter.log',10,10240000)
	# Convert from one format to another
	# params:
	# 	:in_store => input store (inputstream)
	# 	:in_format => input store format
	# 	:out_store => output store (outputstream)
	# 	:out_format => output store format
	# 	:storePass => store password
	# 	:keyPass => key password
	# 	:provider => JCA/JCE provider 
	ConvertKeystore = Proc.new do |params|
		logger = params[:logger] || LOG

		if params[:in_store] != nil 
			if params[:out_store] != nil 
				if params[:in_format] != nil and not params[:in_format].empty?
					if params[:out_format] != nil and not params[:out_format].empty?
					else
						logger.error "out_format param is nil or empty"
						raise KeystoreConverterException.new("out_format param is nil or empty")
					end
				else
					logger.error "in_format param is nil or empty"
					raise KeystoreConverterException.new("in_format param is nil or empty")
				end
			else
				logger.error "out_store param is nil or empty"
				raise KeystoreConverterException.new("out_store param is nil or empty")
			end
		else
			logger.error "in_store param is nil or empty"
			raise KeystoreConverterException.new("in_store param is nil or empty")
		end

		logger.debug "Converting from #{params[:in_format]} to #{params[:out_format]}"

		# exception should already been raised. Reach here means checking is good
		if params[:in_format].downcase == "jks"	or params[:in_format].downcase == "pkcs12" or params[:in_format].downcase == "bks"
			params[:format] = params[:in_format]
			params[:keystoreStream] = params[:in_store]
			logger.debug "[KeystoreConverter.ConvertKeystore] Loading keystore #{params[:in_format]}"
			ks = KeyFactory::JCE::LoadKeyStore.call(params)
			params[:keyName] = ks.aliases.next_element
			if ks.aliases.length > 1
				logger.warn "[KeystoreConverter.ConvertKeystore] In keystore has #{ks.aliases.length} aliases"
			end
			params[:certChain] = ks.getCertificateChain(params[:keyName]).to_a
			logger.debug "[KeystoreConverter.ConvertKeystore] In keystore has #{params[:certChain].length} certificates in chain"
			params[:keypair] = java.security.KeyPair.new(ks.getCertificate(params[:keyName]).getPublicKey,ks.getKey(params[:keyName],params[:keyPass].to_java.toCharArray))
			@kp = params[:keypair]
		elsif params[:in_format].downcase == "pkcs8"
			params[:keystoreStream] = params[:in_store]
			@kp = KeyFactory::PKCS8::LoadKey.call params
			params[:keypair] = @kp
		elsif params[:in_format].downcase == "pem"
			params[:inReader] = params[:in_store]
			@kp = KeyFactory::PEM::LoadKey.call params
			params[:keypair] = @kp
		else
			raise KeystoreConverterException.new("Not supported in format #{params[:in_format]}")
		end

		logger.debug "[KeystoreConverter.ConvertKeystore] In keystore #{params[:in_format]} successfully loaded"

		if params[:out_format].downcase == "jks" or params[:out_format].downcase == "pkcs12" or params[:out_format].downcase == "bks"
			params[:format] = params[:out_format]
			params[:outputStream] = params[:out_store]
			params[:provider] = KeyFactory::JCE::DEFAULT_JCE_PROVIDER if params[:out_format].downcase == "pkcs12" or params[:out_format].downcase == "bks"
			KeyFactory::JCE::StoreKey.call params
		elsif params[:out_format].downcase == "pkcs8"
			params[:keypair] = @kp
			params[:outputStream] = params[:out_store]
			KeyFactory::PKCS8::StoreKey.call params
		elsif params[:out_format].downcase == "pem"
			params[:outWriter] = params[:out_store]
			KeyFactory::PEM::StoreKey.call params
		else
			raise KeystoreConverterException.new("Not supported out format #{params[:out_format]}")
		end

		logger.debug "[KeystoreConverter.ConvertKeystore] Out keystore #{params[:out_format]} successfully saved. Keystore conversion completed successfully"
	end
end
