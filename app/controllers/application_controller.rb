
#VCS_CLASS = {
#  1 => "Git"
#}
VER="V0.1-stabilization-42f36ce74d2adc54272b84e9c6a77c57fbd5580b"

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :isNodeSetup?, :isAuthenticated?

  skip_before_filter :isAuthenticated?, :if => lambda {
    request.local? and request[:format] == "json"
  }

  class FilterType
    attr_reader :name, :options
    def initialize(name)
      @name = name
      @options = []
    end

    def <<(option)
      @options << option
    end
  end

  def isNodeSetup?
    unless File.exist? File.join(Rails.root,"db","owner.id")
      redirect_to :controller => "nodes", :action => "setup"
    end
  end

  def isAuthenticated?
    unless session[:user] != nil
      redirect_to :controller => "users", :action => "login"
    end
  end

	def load_cache_password(node_id)
		syncFile = File.join(Rails.root,"db","sync.key")
		if File.exist?(syncFile)
			File.open(File.join(Rails.root,"db","sync.key")) do |f|
				@cont = f.read
			end
			bin,key = AnCAL::Cipher::ReadEnvelope.call(@cont)
			AnCAL::Cipher::PKCS5_PBKDF2::DecryptData.call(node_id,bin,key)
		else
			raise Exception,"Sync service is not configured. Please contact the node admin to configure the node",caller
		end
	end
end
