class ProjectPackage < ActiveRecord::Base
  attr_accessible :package_id, :project_id

	belongs_to :project
	belongs_to :package

	distributable
	
end
