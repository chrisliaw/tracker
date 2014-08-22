
module AnCAL
	module DataSign
		module PKCS7
			SignData = Proc.new do |pKey,cert,data,detached|
				OpenSSL::PKCS7.sign(cert,pKey,data,[], (detached ? OpenSSL::PKCS7::DETACHED : OpenSSL::PKCS7::BINARY))
			end

			ParseSignedData = Proc.new do |signedData|
				p7 = OpenSSL::PKCS7.new(signedData)
				[p7.detached?,p7.certificates,p7.signers]
			end

			VerifyData = Proc.new do |cert,signedData,orinData = nil,&block|
				store = OpenSSL::X509::Store.new
				store.add_cert(cert)
				# this will only works if add_cert is called
				store.verify_callback = block
				# else default verifier
				#store.verify_callback = lambda do |ok,ctx|
				#	# skip all checking	
				#	true               	
				#end                 	
				p7 = OpenSSL::PKCS7.new(signedData)
				if p7.detached?
					# detached sign
					[p7.verify([cert],store,orinData,OpenSSL::PKCS7::DETACHED),p7]
				else
					# attached sign
					# Not consider the orinData as well
					[p7.verify([cert],store,nil,OpenSSL::PKCS7::BINARY),p7]
				end
			end                    	

		end
	end
end
