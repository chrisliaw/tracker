
require "./dist_credential.rb"

keypair = DistCredential::RSA::GenerateKey.call(1024)
cert = DistCredential::GenerateCertificate.call("chris","chris@antrapol.com","Antrapolation Technology","Solution","KL","MY",keypair,5)

keypair2 = DistCredential::RSA::GenerateKey.call(1024)
cert2 = DistCredential::GenerateCertificate.call("chris2","chris@antrapol.com","Antrapolation Technology","Solution","KL","MY",keypair2,5)

data = "this is testing"
dsigned = DistCredential::SignData.call(keypair,cert,data,true)
asigned = DistCredential::SignData.call(keypair,cert,data,false)

#p DistCredential::VerifyData.call({:detached => true, :cert => cert, :data => data, :signature => dsigned})
#p DistCredential::VerifyData.call({:detached => false, :cert => cert, :data => nil, :signature => asigned})

@verifer = lambda do |ok,ctx|
	if cert != nil and ctx.current_cert != nil and ctx.current_cert.public_key.to_pem == cert.public_key.to_pem
		true
	else
		false
	end
end
# attached sign the data should set to nil
p DistCredential::VerifyData.call({:detached => true, :cert => cert, :data => data, :signature => dsigned },@verifer)
p DistCredential::VerifyData.call({:detached => false, :cert => cert, :data => nil, :signature => asigned },@verifer)

p cert.verify(keypair2)
