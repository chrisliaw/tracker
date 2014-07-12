
VCS_CLASS = {
  1 => "Git"
}

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
end
