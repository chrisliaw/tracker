class Nodes < ActiveRecord::Base
  attr_accessible :identifier, :rights

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
