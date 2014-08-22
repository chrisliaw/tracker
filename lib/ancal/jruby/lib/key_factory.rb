
require 'java'
require 'logger'

Dir.entries(File.join(File.dirname(__FILE__),"..","jars")).each do |f|
	if f != "." and f != ".." and File.extname(f) == ".jar"
		require File.join(File.dirname(__FILE__),"..","jars",f)
	end
end

#require 'bouncy-castle-java'
#require "#{File.join(File.dirname(__FILE__),"jce_key_factory")}"

module AnJCAL
	module KeyFactory

		class KeyFactoryException < Exception
		end

		class KeyStorageException < Exception; end

		# Keep 10 copies of 10 MB
		LOG = Logger.new('keyfactory.log',10,10240000)

		# Method : FileNameToInputStream 
		# Input param :
		#   :type : 
		#     :FileInput : Read and return as File object
		#     :ByteArray : Read and return as byte[]
		#   :name : Name of the file
		#   Use lambda here due to 'return' is used in the coding. If lambda is not used, can use Proc.new
		FileNameToInputStream = lambda do |params|
			f = Java::JavaIo::File.new(params[:name])
			if(f.exists)
				case params[:type]
				when :FileInput
					return Java::JavaIo::FileInputStream.new(f)
				when :ByteArray
					fis = Java::JavaIo::FileInputStream.new(f)
					dis = Java::JavaIo::DataInputStream.new(fis)
					buf = Java::byte[f.length].new
					dis.readFully(buf)
					dis.close
					fis.close
					return buf
				else
					raise KeyStorageException.new("FileNameToInputStream type not recognized")
				end

			else
				raise KeyStorageException.new("File does not exist. Failed to open to input stream")
			end
		end

		# KeyFactory::JCE : JCE implementation here
		module JCE
			# Constant default SecurityProvider
			DEFAULT_JCE_PROVIDER = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new

			# Function: KeyPairGenerator
			# Params:
			#   :type: String to be given to KeyPairGenerator.getInstance()
			#   :size_in_bits: Key size
			#   :provider: Security provider
			KeyPairGenerator = Proc.new do |params| #,provider = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new | 
				provider = params[:provider]
				type = params[:type]
				keyLength = params[:size_in_bits]
				logger = params[:logger] || LOG

				# Provider exist to facilitate key generated in the HSM or external providers
				if provider != nil
					logger.debug "[JCE.KeyPairGenerator] Get #{type} keypair generator with provider #{provider.getName}"
					Java::JavaSecurity::Security::add_provider(provider) 
					keygen = Java::JavaSecurity::KeyPairGenerator::get_instance(type,provider) 
				else
					logger.debug "[JCE.KeyPairGenerator] Get #{type} keypair generator without provider"
					keygen = Java::JavaSecurity::KeyPairGenerator::get_instance(type) 
				end

				# Method 1 : Reflection
				#keygen.java_send :initialize, [Java::int], size_in_bits
				# Method 2 : using java_method
				keygen_init = keygen.java_method :initialize, [Java::int] 
				logger.debug "[JCE.KeyPairGenerator] Initialize keygen with size #{keyLength}"
				keygen_init.call keyLength
				kp = keygen.generate_key_pair() 
				logger.debug "[JCE.KeyPairGenerator] Keypair of #{type} with size #{keyLength} successfully generated"
				kp
			end

			# Function : StoreKey
			# Params
			#   :format : jks,bks,pkcs12 etc. Possible Java supported key type string
			#   :keypair : Keypair which needs to be stored
			#   :existingStoreStream : If there is existing key store exist
			#   :keyName : Alias of the keystore
			#   :storePass : Password of the key store (string)
			#   :keyPass : password of the private key - string (Not all key store supported this, especially HSM key store usually not supported)
			#   :certChain : Certificate chain to be put inside the keystore
			#   :outputStream : OutputStream as constructed keystore to caller
			#   :provider : Security provider used
			StoreKey = Proc.new do |params| # format, keypair, existingStoreStream, keyName, storePass, keyPass, certChain, outputStream, provider|
				format = params[:format]
				keypair = params[:keypair]
				existingStoreStream = params[:existingStoreStream]
				keyName = params[:keyName]
				storePass = params[:storePass]
				keyPass = params[:keyPass]
				certChain = params[:certChain]
				outputStream = params[:outputStream]
				provider = params[:provider] 
				logger = params[:logger] || LOG

				if(keypair == nil)
					logger.error "[JCE.StoreKey] Keypair is null! Store function does not meet entry criteria"
					raise KeyStorageException.new("Keypair is null! Store function does not meet entry criteria")
				elsif(outputStream == nil)
					logger.error "[JCE.StoreKey] Outputstream is null! Store function does not meet entry criteria"
					raise KeyStorageException.new("Outputstream is null! Store function does not meet entry criteria")
				end

				# special handle this sun specific format
				if format.downcase == "jks"
					logger.debug("[JCE.StoreKey] Creating keystore in jks format")
					keystore = Java::JavaSecurity::KeyStore::get_instance(format)
				else
					if provider != nil
						logger.debug "[JCE.StoreKey] Creating #{format} keystore instance with provider #{provider.getName}"
						Java::JavaSecurity::Security::add_provider(provider) 
						keystore = Java::JavaSecurity::KeyStore::get_instance(format,provider)
					else
						logger.debug "[JCE.StoreKey] Creating #{format} keystore instance without provider"
						keystore = Java::JavaSecurity::KeyStore::get_instance(format)
					end
				end

				if(existingStoreStream != nil)
					logger.debug "[JCE.StoreKey] Loading existing keystore"
					keystore.load(existingStoreStream,storePass.to_java.toCharArray)
					existingStoreStream.close
				else
					logger.debug "[JCE.StoreKey] Creating new keystore"
					keystore.load(nil,nil)
				end

				if keyPass != storePass
					logger.warn "[JCE.StoreKey] keyPass not the same as storePass."
				end	
				logger.debug "[JCE.StoreKey] Key name is '#{keyName}'"
				keystore.set_key_entry(keyName, keypair.get_private(),keyPass.to_java.toCharArray,certChain.to_java(Java::JavaSecurityCert::Certificate)) 
				keystore.store(outputStream,storePass.to_java.toCharArray)    
				outputStream.flush
				outputStream.close
				logger.debug "[JCE.StoreKey] Key stored successfully"
			end

			# Function : LoadKey
			# Params:
			#   :format : Format of the keystore. Default to "jks"
			#   :keystoreStream : Keystore in stream format
			#   :storePass : Password to decrypt keystore
			#   :provider : JCE/JCA provider, string or object
			LoadKeyStore = Proc.new do |params|
				format = params[:format] || "jks"
				keystoreStream = params[:keystoreStream]
				storePass = params[:storePass]
				provider = params[:provider] 
				logger = params[:logger] || LOG

				if(keystoreStream == nil)
					logger.error "[JCE.LoadKeyStore] Key store stream is null! Load function does not meet entry criteria"
					raise KeyStorageException.new("Key store stream is null! Load function does not meet entry criteria")
				end

				# Special handling this SUN format
				if format.downcase == "jks"
					logger.debug "[JCE.LoadKeyStore] Loading keystore of jks format"
					keystore = Java::JavaSecurity::KeyStore::get_instance(format)
				else
					if provider != nil
						logger.debug "[JCE.LoadKeyStore] Loading #{format} keystore instance with provider #{provider.getName}"
						Java::JavaSecurity::Security::add_provider(provider) 
						keystore = Java::JavaSecurity::KeyStore::get_instance(format,provider)
					else
						logger.debug "[JCE.LoadKeyStore] Loading #{format} keystore instance without provider"
						keystore = Java::JavaSecurity::KeyStore::get_instance(format)
					end
				end

				if keystoreStream.java_kind_of? java.io.InputStream
					logger.debug "[JCE.LoadKeyStore] Loading keystore from java.io.InputStream"
					keystore.load(keystoreStream,storePass.to_java.toCharArray)
					keystoreStream.close
				else
					logger.debug "[JCE.LoadKeyStore] Loading keystore from byte array"
					keystore.load(Java::JavaIo::ByteArrayInputStream.new(keystoreStream),storePass.to_java.toCharArray)
				end
				#keystore.java_send :load, [Java::JavaIo::ByteArrayInputStream, Java::char[] ],keystoreStream ,storePass.to_java.toCharArray
				logger.debug "[JCE.LoadKeyStore] Keystore loaded successfully"
				keystore
			end

			LoadKeyPair = Proc.new do |params|
				keyPass = params[:keyPass] || params[:storePass]
				keystore = LoadKeyStore.call params
				storeAlias = params[:alias] || keystore.aliases.next_element
				logger = params[:logger] || LOG

				if keystore.aliases.length > 1
					logger.warn "[JCE.LoadKeyPair] Keystore has more then one aliases"
				end

				logger.debug("[JCE.LoadKeyPair] Loading keypair of alias '#{storeAlias}' from keystore")
				kp = Java::JavaSecurity::KeyPair.new(keystore.getCertificate(storeAlias).getPublicKey(),keystore.getKey(storeAlias,keyPass.to_java.toCharArray))
				logger.debug("[JCE.LoadKeyPair] Keypair of alias '#{storeAlias}' loaded successfully")
				kp
			end

			ChangePassphrase = Proc.new do |params|
				format = params[:format] || "jks"
				keystoreStream = params[:keystoreStream]
				outStream = params[:outputStream]
				storePass = params[:storePass]
				keyPass = params[:keyPass] || params[:storePass]
				newStorePass = params[:newStorePass]
				newKeyPass = params[:newKeyPass]
				provider = params[:provider] 
				logger = params[:logger] || LOG

				if(keystoreStream == nil)
					logger.error "[JCE.ChangePassphrase] Key store stream is null! ChangePassphrase function does not meet entry criteria"
					raise KeyStorageException.new("Key store stream is null! ChangePassphrase function does not meet entry criteria")
				end

				ks = LoadKeyStore.call(params)
				params[:keyName] = ks.aliases.next_element
				storeAlias = params[:keyName]
				if ks.aliases.length > 1
					logger.warn "[JCE.ChangePassphrase] Keystore has more then one aliases"
				end
				logger.debug "[JCE.ChangePassphrase] Changing passphrase for alias '#{storeAlias}'"
				params[:keypair] = Java::JavaSecurity::KeyPair.new(ks.getCertificate(storeAlias).getPublicKey(),ks.getKey(storeAlias,keyPass.to_java.toCharArray))
				params[:storePass] = newStorePass
				params[:keyPass] = newKeyPass || params[:storePass]
				params[:certChain] = ks.getCertificateChain(storeAlias).to_java.to_a
				logger.debug "[JCE.ChangePassphrase] Certificate chain has #{params[:certChain].length} certificate(s)"
				StoreKey.call(params)	
				logger.debug "[JCE.ChangePassphrase] JCE keystore passphrase changed successfully"
			end
		end
		# end JCE Implementation

		# KeyFactory::PKCS8 : PKCS8 implementation
		module PKCS8
			DEFAULT_PBE_ALGO = "#{org.bouncycastle.asn1.bc.BCObjectIdentifiers.bc_pbe_sha256_pkcs12_aes256_cbc.getId()}"
			DEFAULT_JCE_PROVIDER = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new
			# PKCS8 Store Key function
			#
			StoreKey = Proc.new do |params| #keypair, storePass, outputStream, pbeAlgo, provider|
				keypair = params[:keypair]
				storePass = params[:storePass]
				outputStream = params[:outputStream]
				pbeAlgo = params[:pbeAlgo] || DEFAULT_PBE_ALGO
				provider = params[:provider] || DEFAULT_JCE_PROVIDER
				logger = params[:logger] || LOG

				if provider != nil
					logger.debug "[PKCS8.StoreKey] Adding provider #{provider.getName}"
					Java::JavaSecurity::Security::add_provider(provider) 
				end

				salt = Java::byte[32].new
				Java::JavaSecurity::SecureRandom.new.nextBytes(salt)
				pbeParamSpec = Java::JavaxCryptoSpec::PBEParameterSpec.new(salt,88)
				pbeKeySpec = Java::JavaxCryptoSpec::PBEKeySpec.new(storePass.to_java.toCharArray)
				if(provider != nil)
					logger.debug "[PKCS8.StoreKey] SecretKeyFactory with algo #{pbeAlgo} provider #{provider.getName}"
					secKeyFact = Java::JavaxCrypto::SecretKeyFactory.getInstance(pbeAlgo,provider)
				else
					logger.debug "[PKCS8.StoreKey] SecretKeyFactory with algo #{pbeAlgo} and no provider"
					secKeyFact = Java::JavaxCrypto::SecretKeyFactory.getInstance(pbeAlgo)
				end
				pbeKey = secKeyFact.generateSecret(pbeKeySpec)

				if(provider != nil)
					logger.debug "[PKCS8.StoreKey] Creating Cipher with algo #{pbeAlgo} provider #{provider.getName}"
					cipher = Java::JavaxCrypto::Cipher.getInstance(pbeAlgo,provider)
				else
					logger.debug "[PKCS8.StoreKey] Creating Cipher with algo #{pbeAlgo} and no provider"
					cipher = Java::JavaxCrypto::Cipher.getInstance(pbeAlgo)
				end

				cipher.init(Java::JavaxCrypto::Cipher::ENCRYPT_MODE,pbeKey,pbeParamSpec)
				output = cipher.doFinal(keypair.getPrivate().getEncoded())

				if(provider != nil)
					logger.debug "[PKCS8.StoreKey] Creating AlgorithmParameters with algo #{pbeAlgo} provider #{provider.getName}"
					algoParam = Java::JavaSecurity::AlgorithmParameters.getInstance(pbeAlgo,provider)
				else
					logger.debug "[PKCS8.StoreKey] Creating Cipher with algo #{pbeAlgo} and no provider"
					algoParam = Java::JavaSecurity::AlgorithmParameters.getInstance(pbeAlgo)
				end

				algoParam.init(pbeParamSpec)
				encPrivInfo = Java::JavaxCrypto::EncryptedPrivateKeyInfo.new(algoParam,output)

				pkcs8Envelope = encPrivInfo.getEncoded()
				outputStream.write(pkcs8Envelope)
				outputStream.flush()
				logger.debug "[PKCS8.StoreKey] PKCS8 StoreKey function successfully completed"
			end

			LoadKey = Proc.new do |params| #pkcs8ByteArray,storePass,provider|
				input = params[:keystoreStream]
				storePass = params[:storePass]
				provider = params[:provider] || DEFAULT_JCE_PROVIDER
				keyType = params[:keyType]
				logger = params[:logger] || LOG

				if provider != nil
					logger.debug "[PKCS8.LoadKey] Adding provider #{provider.getName}"
					Java::JavaSecurity::Security::add_provider(provider) 
				end

				if input.java_kind_of? java.io.InputStream
					logger.debug "[PKCS8.LoadKey] Input is InputStream. Converting to byte array."
					buf = Java::byte[1024].new
					baos = java.io.ByteArrayOutputStream.new
					while(true)
						read = input.read(buf,0,buf.length)
						break if read < 0
						baos.write(buf,0,read)
					end
					input = baos.toByteArray
				end

				encPrivInfo = Java::JavaxCrypto::EncryptedPrivateKeyInfo.new(input)
				cipher = Java::JavaxCrypto::Cipher::getInstance(encPrivInfo.getAlgName())
				pbeKeySpec = Java::JavaxCryptoSpec::PBEKeySpec.new(storePass.to_java.toCharArray)
				if(provider != nil)
					logger.debug "[PKCS8.LoadKey] Generating SecretKeyFactory with algo #{encPrivInfo.getAlgName} provider #{provider.getName}"
					secKeyFact = Java::JavaxCrypto::SecretKeyFactory.getInstance(encPrivInfo.getAlgName(),provider)
				else
					logger.debug "[PKCS8.LoadKey] Generating SecretKeyFactory with algo #{encPrivInfo.getAlgName} with no provider"
					secKeyFact = Java::JavaxCrypto::SecretKeyFactory.getInstance(encPrivInfo.getAlgName())
				end
				pbeKey = secKeyFact.generateSecret(pbeKeySpec)

				cipher.init(Java::JavaxCrypto::Cipher::DECRYPT_MODE, pbeKey,encPrivInfo.getAlgParameters())

				pkcs8KeySpec = encPrivInfo.getKeySpec(cipher)
				#privKeyParam = Java::OrgBouncycastleCryptoUtil::PrivateKeyFactory::createKey(pkcs8KeySpec)

				key = org.bouncycastle.crypto.util.PrivateKeyFactory::createKey(java.io.ByteArrayInputStream.new(pkcs8KeySpec.getEncoded))
				if key.java_kind_of? org.bouncycastle.crypto.params.RSAPrivateCrtKeyParameters
					logger.debug "[PKCS8.LoadKey] Loaded key is RSA key type"
					keyFact = Java::JavaSecurity::KeyFactory.getInstance("RSA")
					privKey = keyFact.generatePrivate(pkcs8KeySpec)
					# here is how to convert into RSAPublicKey, become keypair!
					pubKeySpec = Java::JavaSecuritySpec::RSAPublicKeySpec.new(privKey.getModulus(),privKey.getPublicExponent())
					pubKey = keyFact.generatePublic(pubKeySpec)

					logger.debug "[PKCS8.LoadKey] RSA keypair loaded successfully"
					Java::JavaSecurity::KeyPair.new(pubKey,privKey)
				else
					logger.debug "[PKCS8.LoadKey] Unsupported PKCS8 store of type #{key}"
					raise KeyStorageException.new("Unsupported PKCS8 store of type #{key}")
				end
				#keyFact = Java::JavaSecurity::KeyFactory.getInstance(keyType)
				#privKey = keyFact.generatePrivate(pkcs8KeySpec)
				## here is how to convert into RSAPublicKey, become keypair!
				#pubKeySpec = Java::JavaSecuritySpec::RSAPublicKeySpec.new(privKey.getModulus(),privKey.getPublicExponent())
				#pubKey = keyFact.generatePublic(pubKeySpec)

				#Java::JavaSecurity::KeyPair.new(pubKey,privKey)
				#[privKey,pubKey]
			end

			ChangePassphrase = Proc.new do |params|
				newStorePass = params[:newStorePass]
				logger = params[:logger] || LOG
				logger.debug "[PKCS8.ChangePassphrase] Change passphrase activated"

				keypair = LoadKey.call(params)
				StoreKey.call(params.merge({ :keypair => keypair, :storePass => newStorePass}))
				logger.debug "[PKCS8.ChangePassphrase] Change passphrase completed"
			end
		end
		# End PKCS8 implementation

		# KeyFactory::PEM implementation
		module PEM
			DEFAULT_JCE_PROVIDER = Java::OrgBouncycastleJceProvider::BouncyCastleProvider.new
			DEFAULT_PEM_ENCRYPTION_ALGO = "AES-256-CFB"
			StoreKey = Proc.new do |params|
				keypair = params[:keypair]
				outWriter = params[:outWriter]
				pubOutWriter = params[:pubOutWriter]
				certOutWriter = params[:certOutWriter]
				cert = params[:cert]
				storePass = params[:storePass]
				encryptAlgo = params[:encryptAlgo] || DEFAULT_PEM_ENCRYPTION_ALGO
				logger = params[:logger] || LOG

				if outWriter != nil
					logger.debug "[PEM.StoreKey] Private key out writer defined."
					@writer = org.bouncycastle.openssl.PEMWriter.new(outWriter)
					if storePass != nil and not storePass.empty?
						logger.debug "[PEM.StoreKey] storePass defined. PEM is session key protected"
						encryptor = org.bouncycastle.openssl.jcajce.JcePEMEncryptorBuilder.new(encryptAlgo).build(storePass.to_java.toCharArray)
						@writer.writeObject keypair,encryptor
						logger.debug "[PEM.StoreKey] Encrypted PEM written"
					else
						logger.debug "[PEM.StoreKey] PEM is plain output"
						@writer.writeObject keypair
						logger.debug "[PEM.StoreKey] Plain PEM written"
					end
					@writer.flush
					@writer.close
				end

				if pubOutWriter != nil
					logger.debug "[PEM.StoreKey] Public key out writer defined"
					writer = org.bouncycastle.openssl.PEMWriter.new(pubOutWriter)
					writer.writeObject keypair.getPublic
					writer.flush
					writer.close
					logger.debug "[PEM.StoreKey] Public key written"
				end

				if cert != nil and certOutWriter != nil
					logger.debug "[PEM.StoreKey] Certificate out writer defined"
					writer = org.bouncycastle.openssl.PEMWriter.new(certOutWriter)
					writer.writeObject cert
					writer.flush
					writer.close
					logger.debug "[PEM.StoreKey] Certificate written"
				end
			end

			LoadKey = Proc.new do |params|
				inReader = params[:inReader]
				storePass = params[:storePass]
				logger = params[:logger] || LOG

				if inReader == nil
					logger.error "[PEM.LoadKey] inReader is nil. PEM LoadKey function pre requisite is not met"
					raise KeyStoreException.new "inReader is nil. PEM LoadKey function pre requisite is not met"
				end

				java.security.Security.addProvider DEFAULT_JCE_PROVIDER
				reader = org.bouncycastle.openssl.PEMParser.new(inReader)
				converter = org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter.new.setProvider DEFAULT_JCE_PROVIDER	
				obj = reader.readObject
				if obj.java_kind_of? org.bouncycastle.openssl.PEMKeyPair
					logger.debug "[PEM.LoadKey] Read PEM keypair object"
					@ret = converter.getKeyPair(obj)
				elsif obj.java_kind_of? org.bouncycastle.openssl.PEMEncryptedKeyPair
					logger.debug "[PEM.LoadKey] Read PEM encrypted keypair"
					decryptor = org.bouncycastle.openssl.jcajce.JcePEMDecryptorProviderBuilder.new.setProvider(DEFAULT_JCE_PROVIDER).build(storePass.to_java.toCharArray)
					@ret = converter.getKeyPair(obj.decryptKeyPair(decryptor))
				elsif obj.java_kind_of? org.bouncycastle.asn1.pkcs.PrivateKeyInfo
					logger.debug "[PEM.LoadKey] Read Private Key from PEM"
					@ret = converter.getPrivateKey obj
				elsif obj.java_kind_of? org.bouncycastle.asn1.x509.SubjectPublicKeyInfo
					logger.debug "[PEM.LoadKey] Read Public key from PEM"
					@ret = converter.getPublicKey obj
				elsif obj.java_kind_of? org.bouncycastle.cert.X509CertificateHolder
					logger.debug "[PEM.LoadKey] Read Certificate from PEM"
					@ret = org.bouncycastle.cert.jcajce.JcaX509CertificateConverter.new.setProvider(DEFAULT_JCE_PROVIDER).getCertificate(obj)
				end
				reader.close

				logger.debug "[PEM.LoadKey] LoadKey successful"

				@ret
			end

			ChangePassphrase = Proc.new do |params|
				inReader = params[:inReader]
				storePass = params[:storePass]
				encryptAlgo = params[:encryptAlgo] || DEFAULT_PEM_ENCRYPTION_ALGO
				logger = params[:logger] || LOG

				java.security.Security.addProvider DEFAULT_JCE_PROVIDER
				reader = org.bouncycastle.openssl.PEMParser.new(inReader)
				converter = org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter.new.setProvider DEFAULT_JCE_PROVIDER	
				obj = reader.readObject
				if obj.java_kind_of? org.bouncycastle.openssl.PEMEncryptedKeyPair
					logger.debug "[PEM.ChangePassphrase] Loaded PEM encrypted keypair"
					decryptor = org.bouncycastle.openssl.jcajce.JcePEMDecryptorProviderBuilder.new.setProvider(DEFAULT_JCE_PROVIDER).build(storePass.to_java.toCharArray)
					keypair = converter.getKeyPair(obj.decryptKeyPair(decryptor))
					logger.debug "[PEM.ChangePassphrase] Keypair decrypted."

					storePass = params[:newStorePass]
					outWriter = params[:outWriter]

					@writer = org.bouncycastle.openssl.PEMWriter.new(outWriter)
					encryptor = org.bouncycastle.openssl.jcajce.JcePEMEncryptorBuilder.new(encryptAlgo).build(storePass.to_java.toCharArray)
					@writer.writeObject keypair,encryptor
					@writer.flush
					@writer.close
					logger.debug "[PEM.ChangePassphrase] Encrypted PEM with new password successfully written to output stream"
				else
					logger.debug "[PEM.ChangePassphrase] Given input is not password encrypted. Change passphrase has no effect"
				end
			end
		end	
		# End KeyFactory::PEM implementation

		# Implementation for KeyFactory::SSH key
		module SSH
			# Supporting SSH keystore
			StoreKey = Proc.new do |params|
				keypair = params[:keypair]
				pubOutStream = params[:pubOutStream]
				privOutStream = params[:privOutStream]
				userID = params[:userID]
				storePass = params[:storePass] || nil
				logger = params[:logger] || LOG

				if keypair.getPrivate.java_kind_of? java.security.interfaces:: RSAPrivateKey
					logger.debug "[SSH.StoreKey] Keypair given is RSA keypair"
					# this is rsa encoding
					# Start with public key
					tag = "ssh-rsa"
					pubOutStream.write(tag.to_java.getBytes)
					pubOutStream.write(" ".to_java.getBytes)

					# write the public exponent
					baos = java.io.ByteArrayOutputStream.new
					dos = java.io.DataOutputStream.new baos
					pubExp = keypair.getPrivate.getPublicExponent.to_java.toByteArray
					# write ssh key header
					dos.writeInt(tag.to_java.getBytes.length)
					dos.write(tag.to_java.getBytes)
					dos.writeInt(pubExp.length)
					dos.write(pubExp)
					# write the modulus
					mod = keypair.getPrivate.getModulus.to_java.toByteArray
					dos.writeInt(mod.length)
					dos.write(mod)				
					dos.flush

					baos2 = java.io.ByteArrayOutputStream.new
					dat = baos.toByteArray
					enc = org.bouncycastle.util.encoders::Base64Encoder.new
					enc.encode(dat,0,dat.length,baos2)
					str = java.lang.String.new(baos2.toByteArray)
					str2 = str.to_java.replaceAll("\n","")
					pubOutStream.write(str2.to_java.getBytes)

					pubOutStream.write(" ".to_java.getBytes)
					pubOutStream.write(userID.to_java.getBytes)
					pubOutStream.flush
					logger.debug "[SSH.StoreKey] Done written public key"
					# public key done

					# private key
					# Direct call PEM implementation
					logger.debug "[SSH.StoreKey] Invoking PEM StoreKey implementation for SSH private key storage"
					writer = java.io.OutputStreamWriter.new(privOutStream)
					PEM::StoreKey.call({ :keypair => keypair, :outWriter => writer , :storePass => storePass })
					# end private key
				end
			end
			# end SSH keystore

			# Load SSH keystore
			LoadKey = Proc.new do |params|
				keystoreStream = params[:keystoreStream]
				params[:inReader] = java.io.InputStreamReader.new(keystoreStream)
				logger = params[:logger] || LOG

				logger.debug "[SSH.LoadKey] Delegating to PEM::LoadKey to load SSH keystore"
				PEM::LoadKey.call params
				params[:inReader].close
			end
			# End load SSH keystore
		end
		# End implementation for KeyFactory::SSH key
	end
end

