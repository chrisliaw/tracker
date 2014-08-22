
#require 'bouncy-castle-java'
Dir.entries(File.join(File.dirname(__FILE__),"..","jars")).each do |f|
	if f != "." and f != ".." and File.extname(f) == ".jar"
		require File.join(File.dirname(__FILE__),"..","jars",f)
	end
end

require 'active_support'
require 'active_support/core_ext'
require 'base64'
require 'logger'

class Array
	def to_vector
		v = Java::JavaUtil::Vector.new
		self.each do |rec|
			v.add_element rec
		end
		v
	end
end

module CertFactory
 
  module X509

    class CertFactoryException < Exception; end
    class CertVerificationException < Exception; end

		LOG = Logger.new('certfactory.log',10,10240000)

    DEFAULT_JCE_PROVIDER = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new

    DEFAULT_USER_KEY_USAGE = Java::OrgBouncycastleAsn1X509::KeyUsage.new(Java::OrgBouncycastleAsn1X509::KeyUsage::digitalSignature | Java::OrgBouncycastleAsn1X509::KeyUsage::nonRepudiation | Java::OrgBouncycastleAsn1X509::KeyUsage::dataEncipherment | Java::OrgBouncycastleAsn1X509::KeyUsage::keyEncipherment)
    DEFAULT_CA_KEY_USAGE = Java::OrgBouncycastleAsn1X509::KeyUsage.new(Java::OrgBouncycastleAsn1X509::KeyUsage::digitalSignature | Java::OrgBouncycastleAsn1X509::KeyUsage::nonRepudiation | Java::OrgBouncycastleAsn1X509::KeyUsage::keyEncipherment | Java::OrgBouncycastleAsn1X509::KeyUsage::cRLSign | Java::OrgBouncycastleAsn1X509::KeyUsage::keyCertSign)

		EXT_KEYUSAGE_TLS_SERVER_AUTH = org.bouncycastle.asn1.x509.KeyPurposeId::id_kp_serverAuth
		EXT_KEYUSAGE_TLS_CLIENT_AUTH = org.bouncycastle.asn1.x509.KeyPurposeId::id_kp_clientAuth
		EXT_KEYUSAGE_CODE_SIGNING = org.bouncycastle.asn1.x509.KeyPurposeId::id_kp_codeSigning
		EXT_KEYUSAGE_EMAIL_PROTECTION = org.bouncycastle.asn1.x509.KeyPurposeId::id_kp_emailProtection
		EXT_KEYUSAGE_TIMESTAMPING = org.bouncycastle.asn1.x509.KeyPurposeId::id_kp_timeStamping 

    BuildX509Name = Proc.new do | fields |
      if(fields.is_a?(Hash))
        res = []
        fields.each do |k,v|
          case k
          when :name
            res << "CN=#{v}"
          when :email
            res << "E=#{v}"
          when :org
            res << "O=#{v}"
          when :orgUnit
            res << "OU=#{v}"
          when :country
            res << "C=#{v}"
					when :serialno
						res << "SN=#{v}"
          else
            res << "OU=#{k}-#{v}"
          end
        end
        res.join(",")
      else
        throw Exception.new("Fields given is not hash in BuildX509Name")
      end
    end

    BuildX500Name = Proc.new do | fields |
      if(fields.is_a?(Hash))
        res = []
        fields.each do |k,v|
          case k
          when :name
            res << "CN=#{v}"
          when :email
            res << "EmailAddress=#{v}"
          when :org
            res << "O=#{v}"
          when :orgUnit
            res << "OU=#{v}"
          when :country
            res << "C=#{v}"
          else
            res << "OU=#{k}-#{v}"
          end
        end
        res.join(",")
      else
        throw Exception.new("Fields given is not hash in BuildX500Name")
      end
    end


		# params:
		# 	:cert => certificate to convert in der
		# 	:outWriter => converted certificate
		ConvertCertToPEM = Proc.new do |params|
			cert = params[:cert]
			outWriter = params[:outWriter]

			writer = org.bouncycastle.openssl.PEMWriter.new(outWriter)
			writer.writeObject cert
			writer.flush
		end

    ReadCSRToStream = Proc.new do |file|
      parser = Java::OrgBouncycastleUtilIoPem::PemReader.new(Java::JavaIo::FileReader.new(file))
      ret = parser.readPemObject.getContent()
      parser.close
      ret
    end

		# params
		# 	:in_form => 'pem'/'bin'
		# 	:in => 
    VerifyCSR = Proc.new do |params,&block|#csrByteArray,&block|
      Java::JavaSecurity::Security::add_provider(Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new)
			if params[:in_form] == 'bin'
				@csr = Java::OrgBouncycastlePkcs::PKCS10CertificationRequest.new(params[:in])
			else
				reader = org.bouncycastle.openssl.PEMParser.new(java.io.InputStreamReader.new(java.io.ByteArrayInputStream.new(params[:in])))
				@csr = reader.readObject
			end

			pubKeyDer = @csr.getSubjectPublicKeyInfo.getPublicKey
			pubKey = org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter.new.getPublicKey(@csr.getSubjectPublicKeyInfo)
			verifier = org.bouncycastle.operator.jcajce.JcaContentVerifierProviderBuilder.new().build(pubKey)

      #pubKeyParam = Java::OrgBouncycastleCryptoUtil::PublicKeyFactory::createKey(pubKeyInfo)
      #rsaPubSpec = Java::JavaSecuritySpec::RSAPublicKeySpec.new(pubKeyParam.getModulus(),pubKeyParam.getExponent())
      #keyFact = Java::JavaSecurity::KeyFactory.getInstance("RSA")
      #pubKey = keyFact.generatePublic(rsaPubSpec)

      #verifier = Java::OrgBouncycastleOperatorJcajce::JcaContentVerifierProviderBuilder.new().setProvider(Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new).build(pubKey)
      validated = @csr.isSignatureValid(verifier)
			subj = @csr.getSubject

      if block
				puts "Block given"
				block.call(validated,subj,pubKey)  # allow external verification of subject DN
			else
				puts "No block given"
				[validated,subj,pubKey]
      end
    end

    # pre assumption working with RSA?
    # So far only BC has this capability?
    CSRGenerator = Proc.new do |params|#keypair,subject,signAlgo,digestAlgo,outStream|
			keypair = params[:keypair]
			subject = params[:subject]
			signAlgo = params[:signAlgo] || DEFAULT_SIGNALGO
			digestAlgo = params[:digestAlgo] || DEFAULT_DIGESTALGO
			outStream = params[:outStream]
			logger = params[:logger] || LOG

      Java::JavaSecurity::Security::add_provider(Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new)
			logger.debug "CSR subject is #{subject}"
			x500Principal = javax.security.auth.x500.X500Principal.new(subject)
			p10Builder = org.bouncycastle.pkcs.jcajce.JcaPKCS10CertificationRequestBuilder.new(x500Principal, keypair.getPublic())
			csBuilder = org.bouncycastle.operator.jcajce.JcaContentSignerBuilder.new(signAlgo)
			signer = csBuilder.build(keypair.getPrivate())
			req = p10Builder.build(signer)
      #x500Subj = Java::OrgBouncycastleAsn1X500::X500Name.new(subject)
      #attribute = Java::OrgBouncycastleAsn1X509::Attribute.new(Java::OrgBouncycastleAsn1Pkcs::PKCSObjectIdentifiers::pkcs_9_at_challengePassword,Java::OrgBouncycastleAsn1::DERSet.new(Java::OrgBouncycastleAsn1::DERPrintableString.new("Might be needed by some CA")))
      #signAlgoId = Java::OrgBouncycastleOperator::DefaultSignatureAlgorithmIdentifierFinder.new().find(signAlgo)
      #digestAlgoId = Java::OrgBouncycastleOperator::DefaultDigestAlgorithmIdentifierFinder.new().find(digestAlgo)

      #privKeyParam = Java::OrgBouncycastleCryptoUtil::PrivateKeyFactory::createKey(keypair.getPrivate())
      #privKeyParam = Java::OrgBouncycastleCryptoParams::RSAKeyParameters.new(true,keypair.getPrivate().getModulus(),keypair.getPrivate().getPublicExponent())

      #contentSigner = Java::OrgBouncycastleOperatorBc::BcRSAContentSignerBuilder.new(signAlgoId,digestAlgoId).build(privKeyParam)

      #csrBuilder = Java::OrgBouncycastlePkcsJcajce::JcaPKCS10CertificationRequestBuilder.new(x500Subj,keypair.getPublic())
      #extGenerator = Java::OrgBouncycastleAsn1X509::ExtensionsGenerator.new
      #extGenerator.add_extension(Java::OrgBouncycastleAsn1X509::X509Extension::basicConstraints,true,Java::OrgBouncycastleAsn1X509::BasicConstraints.new(true))
      #extGenerator.add_extension(Java::OrgBouncycastleAsn1X509::X509Extension::basicConstraints,true,Java::OrgBouncycastleAsn1X509::BasicConstraints.new(true))
      #csrBuilder.addAttribute(Java::OrgBouncycastleAsn1Pkcs::PKCSObjectIdentifiers::pkcs_9_at_extensionRequest,extGenerator.generate())
      #req = csrBuilder.build(contentSigner)

      if(outStream != nil)
				logger.debug "[X509.CSRGenerator] Output Stream given. Write CSR to given outputstream"
        writer = Java::OrgBouncycastleUtilIoPem::PemWriter.new(Java::JavaIo::OutputStreamWriter.new(outStream))
        pemObj = Java::OrgBouncycastleUtilIoPem::PemObject.new("CERTIFICATE REQUEST",req.getEncoded())
        writer.writeObject(pemObj)
        writer.flush()
        writer.close()
				logger.debug "[X509.CSRGenerator] CSR written successfully to output stream"
      else
				logger.debug "[X509.CSRGenerator] Returning CSR to caller application"
        req
      end
    end

    DEFAULT_SIGNALGO = "SHA1withRSA"
    DEFAULT_DIGESTALGO = "SHA-1"
    # Function: CertGeneratorFromKeyPair
    # Input:
    #   :userKey : user public key
    #   :subject : subject string in "CN=xxx, E=yyy .. " format
    #   :isIssuer : true indicate the requestor issuing sub CA certificate
    #   &block : block pass in by caller. Block is where CA issuance is done
    CertGeneratorFromKeyPair = Proc.new do | params, &block |
			logger = params[:logger] || LOG

      certGen = Java::OrgBouncycastleX509::X509V3CertificateGenerator.new
      #certGen.set_serial_number Java::JavaMath::BigInteger.new("1")
			if params[:subject].java_kind_of? org.bouncycastle.asn1.x500.X500Name
				certGen.setSubjectDN Java::OrgBouncycastleAsn1X509::X509Name.new params[:subject].to_s
			else
				certGen.setSubjectDN Java::OrgBouncycastleAsn1X509::X509Name.new params[:subject]
			end
      #certGen.setIssuerDN Java::OrgBouncycastleAsn1X509::X509Name.new subject
      #certGen.setNotBefore validFrom
      #certGen.setNotAfter validTo
      certGen.setPublicKey params[:userKey]
      #certGen.setSignatureAlgorithm signAlgo

      certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::SubjectKeyIdentifier, false, org.bouncycastle.x509.extension.SubjectKeyIdentifierStructure.new(params[:userKey])

			if params[:alt_subj] != nil and params[:alt_subj].respond_to? :[]
				logger.debug "[X509.CertGeneratorFromKeyPair] Alternate subject given."
				alt = params[:alt_subj]
				@names = []
				alt.each do |name|
					logger.debug "Alternative name : #{name}"
					@names << org.bouncycastle.asn1.x509::GeneralName.new(org.bouncycastle.asn1.x509::GeneralName::dNSName,name.strip)
				end
				certGen.add_extension org.bouncycastle.asn1.x509::X509Extensions::SubjectAlternativeName, false, org.bouncycastle.asn1.x509::GeneralNames.new(@names.to_java('org.bouncycastle.asn1.x509.GeneralName'))
			end
      #certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::KeyUsage, true, keyUsage

      if(!block)
				logger.error "[X509.CertGeneratorFromKeyPair] Issuer block is not avalable! Issuance halted!"
        raise CertFactoryException.new("Issuer block is not avalable! Issuance halted!")
      end

      cert = block.call params[:isIssuer],certGen
    end

		# Function: CertGeneratorFromKeyPair
		# Input:
		#   :userKey : user public key
		#   :subject : subject string in "CN=xxx, E=yyy .. " format
		#   :isIssuer : true indicate the requestor issuing sub CA certificate
		#   &block : block pass in by caller. Block is where CA issuance is done
		CertGeneratorFromCSR = Proc.new do | params, &block |
			logger = params[:logger] || LOG

			certGen = Java::OrgBouncycastleX509::X509V3CertificateGenerator.new
			#certGen.set_serial_number Java::JavaMath::BigInteger.new("1")
			certGen.setSubjectDN Java::OrgBouncycastleAsn1X500::X500Name.new params[:subject]
			#certGen.setIssuerDN Java::OrgBouncycastleAsn1X509::X509Name.new subject
			#certGen.setNotBefore validFrom
			#certGen.setNotAfter validTo
			certGen.setPublicKey params[:pubKey]
			#certGen.setSignatureAlgorithm signAlgo

			certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::SubjectKeyIdentifier, false, org.bouncycastle.x509.extension.SubjectKeyIdentifierStructure.new(params[:pubKey])
			#certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::KeyUsage, true, keyUsage

			if(!block)
				logger.error "[X509.CertGeneratorFromCSR] Issuer block is not avalable! Issuance halted!"
				raise CertFactoryException.new("Issuer block is not avalable! Issuance halted!")
			end

			cert = block.call params[:isIssuer],certGen
		end

   	# Function : CertIssuerFromKeyPair
    # Input:
    #  :caKeypair : Keypair of the issuer
    #  :issuerDN : Issuer DN string to be put inside the certificate
    #  :keyUsage : Key usage to be put inside the certificate
    #  :validFrom : Start validity date
    #  :validTo : End validity date
    #  :signAlgo : Signing algo
    #  :isIssuer : Is issuing sub CA?
    #  :provider : Security provider
    #  :certGen : BC Certificate generator 
    CertIssuerFromKeyPair = Proc.new do |params| #caKeypair, issuerDn, keyUsage, validFrom, validTo, signAlgo, isIssuer, provider, certGen|
        certGen = params[:certGen]
        caKeypair = params[:caKeypair]
        keyUsage = params[:keyUsage]
        issuerDn = params[:issuerDN]
        validFrom = params[:validFrom]
        validTo = params[:validTo]
        signAlgo = params[:signAlgo] || DEFAULT_SIGNALGO
        provider = params[:provider]
        serial = params[:serial]  # biginteger
				extKeyUsage = params[:extKeyUsage]
				logger = params[:logger] || LOG

        #certGen.set_serial_number Java::JavaMath::BigInteger.new("2")
        certGen.set_serial_number serial
        if(params[:isIssuer])
					logger.debug "[X509.CertIssuerFromKeyPair] Certificate issued is CA"
          certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::BasicConstraints, true, Java::OrgBouncycastleAsn1X509::BasicConstraints.new(true)
				else
					logger.debug "[X509.CertIssuerFromKeyPair] Certificate issued is end user cert"
        end

        certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::AuthorityKeyIdentifier, false, org.bouncycastle.x509.extension.AuthorityKeyIdentifierStructure.new(caKeypair.getPublic())
        certGen.add_extension Java::OrgBouncycastleAsn1X509::X509Extensions::KeyUsage, true, keyUsage

				if extKeyUsage != nil and extKeyUsage.respond_to? :[] and extKeyUsage.length > 0
					certGen.add_extension org.bouncycastle.asn1.x509.X509Extensions::ExtendedKeyUsage, false, org.bouncycastle.asn1.x509.ExtendedKeyUsage.new(extKeyUsage.to_vector)
				end

        certGen.setIssuerDN Java::OrgBouncycastleAsn1X509::X509Name.new issuerDn
        certGen.setNotBefore validFrom
        certGen.setNotAfter validTo
        certGen.setSignatureAlgorithm signAlgo
        if provider != nil
          Java::JavaSecurity::Security::add_provider(provider) 
          cert = certGen.generate(caKeypair.getPrivate(),provider.getName())
					logger.debug "[X509.CertIssuerFromKeyPair] Certificate serial #{serial.to_s} generated successfully"
					cert
        else
          cert = certGen.generate(caKeypair.getPrivate())
					logger.debug "[X509.CertIssuerFromKeyPair] Certificate serial #{serial.to_s} generated successfully"
					cert
        end
    end
  end
end
