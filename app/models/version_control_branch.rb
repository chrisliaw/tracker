class VersionControlBranch < ActiveRecord::Base
  attr_accessible :data_hash, :identifier, :project_status, :vcs_branch, :version_control_id

	belongs_to :version_control
	distributable
end
