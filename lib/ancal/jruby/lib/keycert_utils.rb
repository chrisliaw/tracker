
class ConversionException < Exception; end

module KeystoreUtils
	class FormatConverter
		def self.to_storage(keystore,store_pass = "")
			if keystore.java_kind_of? Java::byte[]
				@keyByte = keystore
			elsif keystore.java_kind_of? java.security.KeyStore
				baos = java.io.ByteArrayOutputStream.new
				keystore.store(baos,store_pass.to_java.toCharArray)
				@keyByte = baos.toByteArray
			else
				raise ConversionException.new "Unsupported keystore format #{keystore}"
			end
			# default storage format is hex
			String.from_java_bytes(Java::OrgBouncycastleUtilEncoders::Hex.encode(@keyByte))
		end

		def self.from_storage(storage)
			if storage.java_kind_of? String
				@objBin = Java::OrgBouncycastleUtilEncoders::Hex.decode(storage)
			else
				raise ConversionException.new "From storage format for keystore #{storage} not supported"
			end
			@objBin
		end

		def self.to_jce_keystore(bin, store_type = "jks", pass = "".to_java.toCharArray, provider = nil)
			if bin.java_kind_of? Java::byte[]
				@storeBin = bin
			elsif bin.java_kind_of? String
				@storeBin = FormatConverter::from_storage_format(bin)
			else
				raise ConversionException.new "Unsupported input format #{bin} for jks keystore conversion"
			end

			if provider != nil
				@ks = java.security.KeyStore.getInstance(store_type,provider)
			else
				@ks = java.security.KeyStore.getInstance(store_type)
			end
			bais = java.io.ByteArrayInputStream.new(@storeBin)
			@ks.load(bais,pass.to_java.toCharArray)

			@ks
		end

		def self.from_storage_to_jce_keystore(storage,pass = "".to_java.toCharArray, store_type = "jks", provider = nil)
			to_jce_keystore(from_storage(storage),store_type,pass,provider)
		end
	end
end

module CertUtils
	class FormatConverter
		def self.to_storage(cert)
			if cert.java_kind_of? Java::byte[]
				@certByte = cert
			elsif cert.java_kind_of? java.security.cert.Certificate
				@certByte = cert.getEncoded
			else
				raise ConversionException.new "Unsupported certificate format #{cert}"
			end

			# default storage format is hex
			String.from_java_bytes(Java::OrgBouncycastleUtilEncoders::Hex.encode(@certByte))
		end

		def self.from_storage(storage)
			objBin = Java::OrgBouncycastleUtilEncoders::Hex.decode(storage)
			#Java::JavaSecurityCert::CertificateFactory::getInstance("X.509").generateCertificate(Java::JavaIo::ByteArrayInputStream.new(objBin))
		end

		def self.to_cert_object(bin)
			prov = CertFactory::X509::DEFAULT_JCE_PROVIDER
			java.security.Security::add_provider(prov)
			Java::JavaSecurityCert::CertificateFactory::getInstance("X.509",prov).generateCertificate(Java::JavaIo::ByteArrayInputStream.new(bin))
		end

		def self.from_storage_to_cert_object(storage)
			to_cert_object(from_storage(storage))	
		end
	end
end

module CSRUtils
	class FormatConverter
		def self.to_storage(csr)
			if csr.java_kind_of? Java::byte[]
				@csrByte = csr
			elsif csr.java_kind_of? org.bouncycastle.pkcs.PKCS10CertificationRequest
				@csrByte = csr.getEncoded
			else
				raise ConversionException.new "Unsupported CSR format #{csr}"
			end

			# default storage format is hex
			String.from_java_bytes(Java::OrgBouncycastleUtilEncoders::Hex.encode(@csrByte))
		end

		def self.from_storage(storage)
			Java::OrgBouncycastleUtilEncoders::Hex.decode(storage)
		end

		def self.from_storage_to_csr_object(bin)
			reader = org.bouncycastle.openssl.PEMParser.new(java.io.InputStreamReader.new(java.io.ByteArrayInputStream.new(bin)))
			@csr = reader.readObject
			if @csr.java_kind_of? org.bouncycastle.pkcs.PKCS10CertificationRequest
				@csr
			else
				raise ConversionException.new "Storage object is not CSR object. It is #{@csr}"
			end
		end
	end
end
