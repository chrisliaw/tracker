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

  private
  def generate_user_id(nodes)
    if nodes.id_path != nil
      if nodes.id_path.respond_to? :read
        @file = nodes.id_path.read
      elsif nodes.id_path.respond_to? :path
        @file = File.read(nodes.id_path.path)
      end
    end

    if @file == nil
      # generate new ID for user
      keypair = DistCredential.generate_key(2048)
      cert = DistCredential.generate_certificate(nodes.name,nodes.email,nodes.orgName,nodes.orgUnit,nodes.state,nodes.country,keypair,3600*24*365*5)
      keystore = DistCredential.generate_keystore(keypair,nodes.pass,nodes.name,nodes.email,cert)
      File.open(File.join(Rails.root,"db","owner.id"),"wb") do |f|
        f.write keystore.to_der
      end
    else
      # activate using existing ID
      begin
        keystore = DistCredential.load_keystore(@file,params["nodes"]["pass"])
        File.open(File.join(Rails.root,"db","owner.id"),"wb") do |f|
          f.write keystore.to_der
        end
      rescue Exception => ex
        p ex
      end 
    end
  end

  def generate_node_unique_id
    node = Node.new
    node.identifier = Digest::SHA1.hexdigest("#{SecureRandom.uuid}")
    puts "Node identifier is #{node.identifier}"
    node.save
  end

end
