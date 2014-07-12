class User < ActiveRecord::Base
  attr_accessible :login, :cert, :cert_validation_token, :status

  validates :login, :presence => true, :uniqueness => true

  stateful :initial => :pending

  transform :pending => :active do
    forward :verify
  end

  transform :active => :suspended do
    forward :suspend
    backward :activate
  end
end
