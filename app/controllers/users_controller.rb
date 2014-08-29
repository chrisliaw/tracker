class UsersController < ApplicationController

  skip_before_filter :isAuthenticated?, :only => [:login, :authenticate]
  # GET /users
  # GET /users.json
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
		@cert = AnCAL::X509::LoadCert.call(@user.cert)
		subj = @user.login
		@subj = {}
		subj.split("/").each do |f|
			sp = f.split("=")
			if sp != nil and sp.length > 0
				@subj[sp[0]] = sp[1]
			end
		end
		@group = params[:groups]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])
		cert = @user.upload_id.read
		certObj = AnCAL::X509::LoadCert.call(cert)
		@user.login = certObj.subject.to_s
		@user.cert = certObj.to_pem
		@user.validation_token = ""
		@user.rights = ""
		@user.groups = User::REMOTE_USER_GROUP

    respond_to do |format|
      if @user.save
        format.html { redirect_to users_path, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

		source = params[:page_source]	
		commit = params[:commit]
		evt = commit.split(" ")[0]
		@user.send("#{evt.downcase}!")
		
		respond_to do |format|
		  if @user.save
				if source != "sync_service"
					format.html { redirect_to @user, notice: 'User was successfully updated.' }
				else
					format.html { redirect_to sync_service_index_path, notice: 'User was successfully updated.' }
				end
				format.json { head :no_content }
      else
        format.html { render action: "show" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
		end

    #respond_to do |format|
    #  if @user.update_attributes(params[:user])
    #    format.html { redirect_to @user, notice: 'User was successfully updated.' }
    #    format.json { head :no_content }
    #  else
    #    format.html { render action: "edit" }
    #    format.json { render json: @user.errors, status: :unprocessable_entity }
    #  end
    #end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
		@group = params[:groups]
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
			if @group == User::REMOTE_USER_GROUP
				format.html { redirect_to sync_service_index_path }
			else
				format.html { redirect_to users_url }
			end
      format.json { head :no_content }
    end
  end

  def login
    render :layout => false 
  end

  def authenticate
    #File.open(File.join(Rails.root,"db","owner.id"),"rb") do |f|
    #  @store_bin = f.read
    #end
    begin
      #puts "pass #{params["user"]["password"]}"
      #u = DistCredential.load_keystore(@store_bin,params["user"]["password"])
			idUrl = File.join(Rails.root,"db","owner.id")
			u = DistCredential::PKCS12::LoadKeyStoreFromURL.call(idUrl,params["user"]["password"])
      sub = u.certificate.subject
      p sub
      sub.to_s.split("/").each do |f|
        if !f.empty? and (f =~ /=/) >= 0
          v = f.split("=")
          if v[0] == "CN"
            @name = v[1]
          elsif v[0] == "emailAddress"
            @login = v[1]
          end
        end
      end
      
      if @login.downcase == params["user"]["login"].downcase
        session[:user] = {}
        session[:user][:login] = @login
        session[:user][:name] = @name
				session[:user][:pass] = params["user"]["password"] 
				cache_password(params["user"]["password"])
        redirect_to :controller => "projects", :action => "index"
      else
        flash[:error] = "Login do not match nodes owner email address"
        redirect_to :action => "login"
      end
    rescue Exception => e
      p e
      flash[:error] = "Password is incorrect"
      redirect_to :action => "login"
    end
    #u = User.find :first, :conditions => ["login = ?",params["user"]["login"]] 
    #
    #if u == nil
    #  flash[:error] = "User not found."
    #  redirect_to :action => "login"
    #elsif u.pass != params["user"]["password"]
    #  flash[:error] = "Password incorrect"
    #  redirect_to :action => "login"
    #else
    #  session[:user] = {}
    #  session[:user][:id] = u.id
    #  session[:user][:login] = u.login
    #  session[:user][:name] = u.name
    #  redirect_to :controller => "projects", :action => "index"
    #end
  end

  def logout
    session[:user] = nil
    redirect_to :controller => "projects", :action => "index"
  end

	def show_owner_detail
		idUrl = File.join(Rails.root,"db","owner.id")
		pkey,@cert,chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,session[:user][:pass])
	end

	def download_cert
		idUrl = File.join(Rails.root,"db","owner.id")
		pkey,@cert,chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,session[:user][:pass])	
		subj = AnCAL::X509::ParseName.call(@cert.subject.to_s)
		p subj["emailAddress"]
		send_data @cert.to_pem, :filename => "#{subj["emailAddress"]}.tid"
	end

	def change_password
		
	end

	def update_password
		oldPass = params[:user][:old_pass]
		newPass = params[:user][:pass]
		newPass2 = params[:user][:pass_confirm]

		idUrl = File.join(Rails.root,"db","owner.id")
		begin
			@pkey,@cert,@chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,oldPass)
			if newPass != newPass2
				flash[:error] = "Password do not match. Please try again."
				redirect_to change_password_users_path
			else

				begin
					ks = @pkey.to_pkcs12(newPass,@cert,@chain,"")
					File.open(idUrl,"wb") do |f|
						f.write ks.to_der
					end
					session[:user][:pass] = newPass
					cache_password(newPass)
					flash[:notice] = "Owner password changed successfully"
					redirect_to show_owner_detail_users_path
				rescue Exception => ex
					flash[:error] = "Change password exception. Error was #{ex}" 
					redirect_to change_password_users_path
				end
			end
		rescue Exception => ex
			flash[:error] = "Old password does not matched. Please try again." 
			redirect_to change_password_users_path
		end

	end

	private
	def cache_password(pass)
		node = Node.first
		bin,key = AnCAL::Cipher::PKCS5_PBKDF2::EncryptData.call(node.identifier,pass)
		File.open(File.join(Rails.root,"db","sync.key"),"wb") do |f|
			f.write AnCAL::Cipher::GenEnvelope.call(bin,key)
		end
	end
end
