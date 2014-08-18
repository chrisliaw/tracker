class DvcsConfig < ActiveRecord::Base
  attr_accessible :name, :path

	distributable
end
