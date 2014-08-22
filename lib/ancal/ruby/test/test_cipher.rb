require 'minitest/autorun'
require "#{File.join(File.dirname(__FILE__),"..","ancal_ruby")}"

class TestCipher < MiniTest::Test
	def test_pkcs7
		ca_pkey = AnCAL::KeyFactory::GenerateKey.call(2048)
		cn = AnCAL::X509::CertName.new
		cn.name = "Chris CA"
		cn.email = "chrisliaw@antrapol.com"
		cn.add_org_info("Antrapolation Technology Sdn Bhd")
		cn.add_org_unit_info("Solution")
		ca_cert = AnCAL::X509::GenerateCert.call(cn,ca_pkey,2,AnCAL::X509::CERT_HASH_SHA2)

		pkey = AnCAL::KeyFactory::GenerateKey.call(2048)
		cn = AnCAL::X509::CertName.new
		cn.name = "Chris"
		cn.email = "chrisliaw@antrapol.com"
		cn.add_org_info("Antrapolation Technology Sdn Bhd")
		cn.add_org_unit_info("Solution")
		cert = AnCAL::X509::GenerateCert.call(cn,pkey) do |cert|
			cert.issuer = ca_cert.subject
			cert.not_before = Time.now
			# Time.now is represented in second
			cert.not_after = Time.now+(3*365*24*60*60)
			extFact = OpenSSL::X509::ExtensionFactory.new
			extFact.subject_certificate = cert
			extFact.issuer_certificate = ca_cert
			#cert.add_extension(extFact.create_extension "basicConstraints","CA:TRUE")
			cert.add_extension(extFact.create_extension "subjectKeyIdentifier",'hash')
			#cert.add_extension(extFact.create_extension 'keyUsage','keyEncipherment,dataEncipherment,digitalSignature,nonRepudiation,keyAgreement,keyCertSign,cRLSign')
			cert.add_extension(extFact.create_extension 'keyUsage','keyEncipherment,dataEncipherment,digitalSignature,nonRepudiation')

			cert.serial = 11
			cert.sign(ca_pkey,AnCAL::X509::CERT_HASH_SHA1)
		end

		data = "this is data for testing"
		encData = AnCAL::Cipher::PKCS7::EncryptData.call(ca_cert,data)
		File.open("c.enc","w") do |f|
			f.write encData
		end
		decData = AnCAL::Cipher::PKCS7::DecryptData.call(ca_pkey,ca_cert,encData)
		assert_equal(data,decData)
		tmpEnc = encData.to_hex
		rbin = tmpEnc.hex_to_bin
		decData = AnCAL::Cipher::PKCS7::DecryptData.call(ca_pkey,ca_cert,rbin)
		assert_equal(data,decData)
		assert_raises OpenSSL::PKCS7::PKCS7Error do
			# wrong cert to decrypt
			decData = AnCAL::Cipher::PKCS7::DecryptData.call(pkey,cert,encData)
		end
	end

	def test_pkcs5_basic
		data = "this is super secret data to be protected"
		encData = AnCAL::Cipher::PKCS5Basic::EncryptData.call("password",data)
		plain = AnCAL::Cipher::PKCS5Basic::DecryptData.call("password",encData[0],encData[1])
		assert_equal(data,plain)
		plain = AnCAL::Cipher::PKCS5Basic::DecryptData.call("passwords",encData[0],encData[1])
		refute_equal(data,plain)
	end

	def test_pkcs5_pbkdf2
		data = "this is again a new super secret data to be protected"
		encData = AnCAL::Cipher::PKCS5_PBKDF2::EncryptData.call("pass",data)
		plain = AnCAL::Cipher::PKCS5_PBKDF2::DecryptData.call("pass",encData[0],encData[1])
		assert_equal(data,plain)
		plain = AnCAL::Cipher::PKCS5_PBKDF2::DecryptData.call("passd",encData[0],encData[1])
		refute_equal(data,plain)
		plain = AnCAL::Cipher::PKCS5_PBKDF2::DecryptData.call("pass",encData[0],encData[1],2000)
		refute_equal(data,plain)
	end
end
