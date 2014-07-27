
require 'openssl'
include OpenSSL

class DistCredential
	def self.generate_key(size)
		PKey::RSA.generate size
	end

	def self.load_keystore(store_bin,pass)
		PKCS12.new(store_bin,pass)
	end

	def self.generate_certificate(name,email,orgName,orgUnit,state,country,keypair,duration,&block)
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

	def self.keystore_to_keypair(keystore)
		PKey::RSA.new keystore.key
	end

	def self.generate_keystore(keypair,password,name,email,cert,ca_certs = [])
		if !(ca_certs.kind_of? Array)
			ca_certs = [ca_certs]
		end
		PKCS12.create(password,"Keystore for user #{name} who carries email #{email}",keypair,cert,ca_certs)
	end

	def self.sign(keystore,data,detached = true)
    OpenSSL::PKCS7.sign(keystore.certificate,keystore.key,data,[],(detached ? OpenSSL::PKCS7::DETACHED : OpenSSL::PKCS7::ATTACHED))
  end

	def self.verify(data,signature,keystore)
    store = OpenSSL::X509::Store.new
    store.add_cert(keystore.certificate)
    store.verify_callback = lambda do |ok,ctx|
      true
    end

    p7 = OpenSSL::PKCS7::PKCS7.new(signature)
    p7.verify([keystore.certificate],store,data,OpenSSL::PKCS7::DETACHED)
  end
end

#keypair = DistCredential.generate_key(1024)
#self_sign_cert = DistCredential.generate_certificate("Chris","chris@test.com","Antrapol","Solution","KL","MY",keypair,3600*24*365*5)
#p self_sign_cert
#ks = DistCredential.load_keystore(File.read("user.p12"),"password")
#ca_keypair = DistCredential.keystore_to_keypair(ks)
#cert = DistCredential.generate_certificate("June","june@test.com","Antrapol","Solution","KL","MY",keypair,3600*24*365*5) do |cert|
#	cert.serial = 100
#	cert.issuer = ks.certificate.subject
#	cert.sign(ca_keypair,OpenSSL::Digest::SHA1.new)
#end
#p cert
