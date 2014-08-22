
module AnCAL
	module Cipher
		DEFAULT_SYM_ALGO = "AES-256-CFB"
		module PKCS5Basic
			EncryptData = Proc.new do |pass,data,alg = DEFAULT_SYM_ALGO|
				salt = OpenSSL::Random.random_bytes(8)

				cipher = OpenSSL::Cipher::Cipher.new(alg)
				cipher.pkcs5_keyivgen(pass,salt)
				cipher.encrypt
				out = cipher.update(data)
				out << cipher.final
				[out,salt]
			end

			DecryptData = Proc.new do |pass,encData,salt,alg = DEFAULT_SYM_ALGO|
				cipher = OpenSSL::Cipher::Cipher.new(alg)
				cipher.pkcs5_keyivgen(pass,salt)
				cipher.decrypt
				out = cipher.update(encData)
				out << cipher.final
				out
			end
		end

		module PKCS5_PBKDF2
			EncryptData = Proc.new do |pass,data,iteration = 6000,alg = DEFAULT_SYM_ALGO|
				salt = OpenSSL::Random.random_bytes(8)

				cipher = OpenSSL::Cipher.new(alg)
				cipher.encrypt
				kiv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(pass,salt,iteration,cipher.key_len+cipher.iv_len)
				key = kiv[0,cipher.key_len]
				iv = kiv[cipher.key_len,cipher.iv_len]

				cipher.key = key
				cipher.iv = iv

				out = cipher.update(data)
				out << cipher.final
				[out,salt]
			end

			DecryptData = Proc.new do |pass,encData,salt,iteration = 6000,alg = DEFAULT_SYM_ALGO|
				cipher = OpenSSL::Cipher.new(alg)
				cipher.decrypt

				kiv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(pass,salt,iteration,cipher.key_len+cipher.iv_len)
				key = kiv[0,cipher.key_len]
				iv = kiv[cipher.key_len,cipher.iv_len]

				cipher.key = key
				cipher.iv = iv

				out = cipher.update(encData)
				out << cipher.final
				out
			end
		end

		module PKCS7
			#SignData = Proc.new do |pKey,cert,data,detached|
			#	OpenSSL::PKCS7.sign(cert,pKey,data,[], (detached ? OpenSSL::PKCS7::DETACHED : OpenSSL::PKCS7::BINARY))
			#end

			#VerifyData = Proc.new do |cert,signedData,orinData,detached,&block|
			#	store = OpenSSL::X509::Store.new
			#	store.add_cert(cert)
			#	# this will only works if add_cert is called
			#	store.verify_callback = block
			#	# else default verifier
			#	#store.verify_callback = lambda do |ok,ctx|
			#	#	# skip all checking	
			#	#	true               	
			#	#end                 	
			#	p7 = OpenSSL::PKCS7.new(signedData)
			#	p7.verify([cert],store,orinData,(detached ? OpenSSL::PKCS7::DETACHED : OpenSSL::PKCS7::BINARY))
			#end                    	
                             
			EncryptData = Proc.new 	do |cert,data,alg = DEFAULT_SYM_ALGO|
				cipher = OpenSSL::Cipher::Cipher.new(alg)
				OpenSSL::PKCS7::encrypt([cert],data,cipher,OpenSSL::PKCS7::BINARY).to_der
			end                    	
                             
			DecryptData = Proc.new  do |pkey,cert,encData|
				dec = OpenSSL::PKCS7.new(encData)
				dec.decrypt(pkey,cert)
			end
		end
	end
end
