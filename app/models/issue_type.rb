class IssueType < ActiveRecord::Base
  attr_accessible :desc, :name, :state
  has_many :issues
  
  stateful :initial => :active

  transform :active => :inactive do
    forward :inactivate
    backward :activate
  end

end
