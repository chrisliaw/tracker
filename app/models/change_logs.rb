class ChangeLogs < ActiveRecord::Base
  attr_accessible :key, :operation, :table
end
