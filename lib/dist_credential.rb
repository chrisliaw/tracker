
require 'openssl'
include OpenSSL

module DistCredential
	module RSA
		GenerateKey = Proc.new do |keysize|
			PKey::RSA.generate keysize
		end
	end

	module PKCS12
		LoadKeyStoreFromURL = Proc.new do |url,pass|
			File.open(url,"rb") do |f|
				@storeBin = f.read
			end
			OpenSSL::PKCS12.new(@storeBin,pass)
		end	

		ConstructKeyStore = Proc.new do |keypair,password,name,email,cert,friendlyString,ca_certs = []|
			if ca_certs != nil and !(ca_certs.kind_of? Array)
				ca_certs = [ca_certs]
			end
			friendlyString = "Key for user #{name} (#{email})" if friendlyString == nil or friendlyString.empty?
			OpenSSL::PKCS12.create(password,friendlyString,keypair,cert,ca_certs)
		end

		ConstructKeyPairFromStore = Proc.new do |keystore|
			PKey::RSA.new keystore.key
		end
	end

	SignData = Proc.new do |privKey,cert,data,detached|
    OpenSSL::PKCS7.sign(cert,privKey,data,[],(detached ? OpenSSL::PKCS7::DETACHED : OpenSSL::PKCS7::BINARY))
	end

	VerifyData = Proc.new do |params|
		detached = params[:detached]
		cert = params[:cert]
		data = params[:data]
		signature = params[:signature]

    store = OpenSSL::X509::Store.new
    store.add_cert(cert)
    store.verify_callback = lambda do |ok,ctx|
			#p [ctx.current_cert.subject.to_s,ok,ctx.error_string]
			#p ctx.current_cert.public_key.to_pem
			#p cert.public_key.to_pem
			# check cert is all here
			if cert != nil and ctx.current_cert != nil and ctx.current_cert.public_key.to_pem == cert.public_key.to_pem
				true
			else
				false
			end
    end

    p7 = OpenSSL::PKCS7::PKCS7.new(signature)
    p7.verify([cert],store,data,(detached ? OpenSSL::PKCS7::DETACHED : OpenSSL::PKCS7::BINARY))
	end

	GenerateCertificate = Proc.new do |name,email,orgName,orgUnit,state,country,keypair,duration,&block|
		cert = X509::Certificate.new
		cert.version = 2
		cert.issuer = X509::Name.new([["CN",name],["emailAddress",email],["O",orgName],["OU",orgUnit],["ST",state],["C",country]])
		cert.subject = cert.issuer
		cert.public_key = keypair.public_key
		cert.not_before = Time.now
		cert.not_after = Time.now+duration

		extFact = OpenSSL::X509::ExtensionFactory.new(nil,cert)
		cert.extensions = [extFact.create_extension("subjectKeyIdentifier",'hash'),extFact.create_extension('keyUsage','keyEncipherment,dataEncipherment,digitalSignature')]

		if block != nil
			cert.extensions << extFact.create_extension("basicConstraints","CA:TRUE")
			cert = block.call(cert)
		else
			cert.serial = 1
			cert.sign(keypair,OpenSSL::Digest::SHA1.new)
		end
		cert
	end
end
