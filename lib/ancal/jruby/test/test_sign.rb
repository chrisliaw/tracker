require 'minitest/autorun'
require "#{File.join(File.dirname(__FILE__),"..","ancal")}"

class TestSign < MiniTest::Test
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
		# test attached sign
		aSign = AnCAL::DataSign::PKCS7::SignData.call(ca_pkey,ca_cert,data,false)
		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,aSign,nil,false) do |ok,ctx|
			true
		end
		assert_equal(st,true)

		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,aSign,nil,false) do |ok,ctx|
			false
		end
		assert_equal(false,st)

		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,aSign,nil,false) do |ok,ctx|
			if ctx.current_cert.public_key.to_pem == ca_cert.public_key.to_pem
				true
			else
				false
			end
		end
		assert_equal(true,st)
		assert_equal(aSign.data,data)
		# done attached sign testing
		
		# test detached sign
		dSign = AnCAL::DataSign::PKCS7::SignData.call(ca_pkey,ca_cert,data,true)
		# test data myst be present to get true status even our block say true
		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,dSign,nil,true) do |ok,ctx|
			true
		end
		assert_equal(false,st)

		# test the data must be present to get true status
		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,dSign,data,true) do |ok,ctx|
			true
		end
		assert_equal(true,st)

		# test the status will depending on cert verification if data verified ok
		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,dSign,data,false) do |ok,ctx|
			true
		end
		assert_equal(true,st)

		# test the status will depending on cert verification if data verified ok
		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,dSign,data,true) do |ok,ctx|
			false
		end
		assert_equal(false,st)

		# test invalid data..even block return true, data failed to be verified
		st = AnCAL::DataSign::PKCS7::VerifyData.call(ca_cert,dSign,"#{data}+",true) do |ok,ctx|
			true
		end
		assert_equal(false,st)
		# done detached sign testing
	end
end
