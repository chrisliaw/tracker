
require 'openssl'

module AnCAL
	module X509
		CERT_HASH_SHA1 = OpenSSL::Digest::SHA1.new
		CERT_HASH_SHA2 = OpenSSL::Digest::SHA256.new
		class CertName
			attr_accessor :name, :email, :state, :country
			def initialize
				@org = []
				@orgUnit = []
			end

			def add_org_info(info)
				@org << ["O",info]
			end

			def add_org_unit_info(info)
				@orgUnit << ["OU",info]
			end

			def to_x509_name
				fields = []
				fields << ["CN",@name]
				fields << ["emailAddress",@email]
				fields += @org
				fields += @orgUnit
				fields << ["ST",@state] if @state != nil and not @state.empty?
				fields << ["C",@country] if @country != nil and not @country.empty?
				OpenSSL::X509::Name.new(fields)
			end
		end

		LoadCert = Proc.new do |cert|
			OpenSSL::X509::Certificate.new(cert)
		end

		GenerateCert = Proc.new do |cert_name, pkey, cert_length = 3, hashAlgo = CERT_HASH_SHA1, &block|
			cert = OpenSSL::X509::Certificate.new
			cert.version = 2
			cert.subject = cert_name.to_x509_name #X509::Name.new([["CN",name],["emailAddress",email],["O",orgName],["OU",orgUnit],["ST",state],["C",country]])
			cert.public_key = pkey.public_key
			if block
				cert = block.call(cert)
			else
				cert.serial = 1
				cert.issuer = cert.subject
				cert.not_before = Time.now
				# Time.now is represented in second
				cert.not_after = Time.now+(cert_length*365*24*60*60)
				extFact = OpenSSL::X509::ExtensionFactory.new
				extFact.subject_certificate = cert
				extFact.issuer_certificate = cert
				cert.add_extension(extFact.create_extension "basicConstraints","CA:TRUE")
				cert.add_extension(extFact.create_extension "subjectKeyIdentifier",'hash')
				cert.add_extension(extFact.create_extension 'keyUsage','keyEncipherment,dataEncipherment,digitalSignature,nonRepudiation,keyAgreement,keyCertSign,cRLSign')

				#cert.sign(pkey,OpenSSL::Digest::SHA1.new)
				cert.sign(pkey,hashAlgo)
			end

			#if block != nil
			#	cert.extensions << extFact.create_extension("basicConstraints","CA:TRUE")
			#	cert = block.call(cert)
			#else
			#	cert.serial = 1
			#	cert.sign(keypair,OpenSSL::Digest::SHA1.new)
			#end
			cert
		end
	end
end
