class DvcsConfig < ActiveRecord::Base
  attr_accessible :name, :path, :identifier, :data_hash

	distributable
end
