class User < ActiveRecord::Base
  attr_accessible :login, :cert, :cert_validation_token, :status

  #validates :login, :presence => true, :uniqueness => true

	REMOTE_USER_GROUP = "RU"
	REMOTE_HOST_GROUP = "RH"

	GroupToName = {
		REMOTE_USER_GROUP => "Remote User",
		REMOTE_HOST_GROUP => "Remote Host"
	}

  stateful :initial => :pending

  transform :pending => :active do
    forward :verified
  end

  transform :active => :suspended do
    forward :suspend
    backward :activate
  end
end
