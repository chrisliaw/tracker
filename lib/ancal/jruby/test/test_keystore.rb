require 'minitest/autorun'
require "#{File.join(File.dirname(__FILE__),"..","ancal")}"

class TestKeystore < MiniTest::Test
	def test_pkcs12
		pkey = AnCAL::KeyFactory::GenerateKey.call(2048)
		cn = AnCAL::X509::CertName.new
		cn.name = "Chris"
		cn.email = "chrisliaw@antrapol.com"
		cn.add_org_info("Antrapolation Technology Sdn Bhd")
		cn.add_org_unit_info("Solution")
		cert = AnCAL::X509::GenerateCert.call(cn,pkey,1)

		p12 = pkey.to_pkcs12("pass",cert,[],"For Chris")
		File.open("t.p12","w") do |f|
			f.write p12.to_der
		end
	end

	def test_pkcs12_with_ca
		ca_pkey = AnCAL::KeyFactory::GenerateKey.call(2048)
		cn = AnCAL::X509::CertName.new
		cn.name = "Chris CA"
		cn.email = "chrisliaw@antrapol.com"
		cn.add_org_info("Antrapolation Technology Sdn Bhd")
		cn.add_org_unit_info("Solution")
		ca_cert = AnCAL::X509::GenerateCert.call(cn,ca_pkey,2,AnCAL::X509::CERT_HASH_SHA2)
		File.open("ca.crt","w") do |f|
			f.write ca_cert.to_pem
		end

		File.open("ca.p12","w") do |f|
			f.write ca_pkey.to_pkcs12('pass',ca_cert).to_der
		end

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


			cert.serial = 10
			cert.sign(ca_pkey,AnCAL::X509::CERT_HASH_SHA1)
		end

		File.open("user.crt","w") do |f|
			f.write cert.to_pem
		end

		File.open("user.p12","w") do |f|
			f.write pkey.to_pkcs12('pass2',cert,[ca_cert]).to_der
		end

	end
end
