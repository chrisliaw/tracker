class Package < ActiveRecord::Base
  attr_accessible :name
	has_many :project_packages
	has_many :projects, :through => :project_packages
	has_many :develements

	distributable
end
