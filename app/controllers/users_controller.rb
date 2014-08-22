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

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
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

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
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
end
