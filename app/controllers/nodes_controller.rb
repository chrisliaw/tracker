class NodesController < ApplicationController
  skip_before_filter :isNodeSetup?, :isAuthenticated?

  def setup
    render :layout => false
  end

  def init
    @nodes = Node.new
    @nodes.name = params["nodes"]["name"] 
    @nodes.email = params["nodes"]["email"] 
    @nodes.orgName = params["nodes"]["orgName"] 
    @nodes.orgUnit = params["nodes"]["orgUnit"] 
    @nodes.state = params["nodes"]["state"] 
    @nodes.country = params["nodes"]["country"] 
    @nodes.id_path = params["nodes"]["id_path"] 
    @nodes.pass = params["nodes"]["pass"]
    @nodes.pass_confirmation = params["nodes"]["pass_confirmation"]

    generate_user_id(@nodes)
    generate_node_unique_id

    redirect_to projects_path
  end

	def index
		@nodes = Node.where(["id > 1"])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users }
		end
	end

	def show
		@node = Node.find(params[:id])
		if @node.submitted_by != nil and not @node.submitted_by.empty?
			@cert = AnCAL::X509::LoadCert.call(@node.submitted_by)
			@subj = AnCAL::X509::ParseName.call(@cert.subject.to_s)
		else
			@cert = nil
			@subj = {}
		end
	end

	def new
		@node = Node.new	
	end

	def create
    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        format.html { redirect_to @node, notice: 'User was successfully created.' }
        format.json { render json: @node, status: :created, location: @node }
      else
        format.html { render action: "new" }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
	end

	def edit
		@node = Nodes.find(params[:id])
	end

	def update
		@node = Nodes.find(params[:id])
		commit = params[:commit]
		sp = commit.split(" ")
		if sp[1] == "Node"
			@node.send "#{sp[0].downcase}!"
		end

		respond_to do |format|
      if @node.update_attributes(params[:nodes])
      #if @node.save
        format.html { redirect_to nodes_path, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
	end

	def destroy
		@node = Node.find params[:id]
		@node.destroy

		respond_to do |format|
			format.html { redirect_to nodes_path, notice: 'User was successfully deleted.' }
			format.json { head :no_content }
		end
	end

  private
  def generate_user_id(nodes)
    if nodes.id_path != nil
      if nodes.id_path.respond_to? :read
        #@file = nodes.id_path.read
        @file = nodes.id_path
      elsif nodes.id_path.respond_to? :path
        #@file = File.read(nodes.id_path.path)
        @file = nodes.id_path.path
      end
    end

    if @file == nil
      # generate new ID for user
      #keypair = DistCredential.generate_key(2048)
			keypair = DistCredential::RSA::GenerateKey.call(2048)
      #cert = DistCredential.generate_certificate(nodes.name,nodes.email,nodes.orgName,nodes.orgUnit,nodes.state,nodes.country,keypair,3600*24*365*5)
			cert = DistCredential::GenerateCertificate.call(nodes.name,nodes.email,nodes.orgName,nodes.orgUnit,nodes.state,nodes.country,keypair,3600*24*365*5)
      #keystore = DistCredential.generate_keystore(keypair,nodes.pass,nodes.name,nodes.email,cert)
			keystore = DistCredential::PKCS12::ConstructKeyStore.call(keypair,nodes.pass,nodes.name,nodes.email,cert,"Tracker Node ID #{nodes.name} (#{nodes.email})",[cert])
      File.open(File.join(Rails.root,"db","owner.id"),"wb") do |f|
        f.write keystore.to_der
      end
    else
      # activate using existing ID
      begin
        #keystore = DistCredential.load_keystore(@file,params["nodes"]["pass"])
				keystore = DistCredential::PKCS12::LoadKeyStoreFromURL.call(nodes.id_path.path,params["nodes"]["pass"])
        File.open(File.join(Rails.root,"db","owner.id"),"wb") do |f|
          f.write keystore.to_der
        end
      rescue Exception => ex
        p ex
      end 
    end
  end

  def generate_node_unique_id
		node = Node.first
		if node == nil
			node = Node.new
			node.identifier = Digest::SHA1.hexdigest("#{SecureRandom.uuid}")
			puts "Generated node identifier #{node.identifier}"
			node.save
		else
			puts "Node already has identifier #{node.identifier} generated. Skipped generating node id"
		end
    #node = Node.new
    #node.identifier = Digest::SHA1.hexdigest("#{SecureRandom.uuid}")
    #puts "Generated node identifier #{node.identifier}"
    #node.save
  end

end
