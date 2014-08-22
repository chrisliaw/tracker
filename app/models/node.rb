
class Node < ActiveRecord::Base
  attr_accessible :identifier, :rights
  #attr_accessor :name, :email, :orgName, :orgUnit, :state, :country, :id_path, :pass, :pass_confirmation
	
	validates :identifier, :presence => true, :uniqueness => true

	stateful :initial => :pending

	transform :pending => :active do
		forward :verified
	end

	transform :active => :suspended do
		forward :suspend
		backward :activate
	end
end
