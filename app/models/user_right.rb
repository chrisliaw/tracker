class UserRight < ActiveRecord::Base
  attr_accessible :domain, :right, :user_id
end
