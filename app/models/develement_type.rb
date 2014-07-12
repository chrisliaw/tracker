class DevelementType < ActiveRecord::Base
  attr_accessible :desc, :name, :state
  has_many :develements

  stateful :initial => :active

  transform :active => :inactive do
    forward :inactivate
    backward :activate
  end

end
