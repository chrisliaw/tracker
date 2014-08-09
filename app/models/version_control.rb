class VersionControl < ActiveRecord::Base
  attr_accessible :created_by, :name, :updated_by, :upstream_vcs_class, :upstream_vcs_path, :vcs_class, :vcs_path, :versionable_id, :versionable_type, :state, :pushable_repo, :upstream_vcs_branch, :vcs_branch, :notes

  belongs_to :versionable, :polymorphic => true

	has_many :version_control_branches

  validates :name, :presence => true
  #validates :upstream_vcs_path, :presence => true, :if => lambda { self.pushable_repo == nil or self.pushable_repo == 0 or (self.vcs_path == nil or self.vcs_path.empty?) }
  validates :upstream_vcs_path, :presence => true, :if => lambda { self.vcs_path == nil or self.vcs_path.empty? }
  validates :vcs_path, :presence => true, :if => lambda { self.pushable_repo == 1 or self.upstream_vcs_path == nil or self.upstream_vcs_path.empty? }

	def already_defined_schedule_states
		@definedSchedule = []
		self.version_control_branches.each do |vcb|
			@definedSchedule << vcb.project_status
		end
		@definedSchedule
	end

	def dvcs_path
		dvcs = DvcsConfig.find(self.upstream_vcs_class)
		if dvcs != nil
			dvcs.path
		else
			""
		end
	end

	distributable
  stateful :initial => :active

  transform :active => :inactive do
    forward :inactivate
    backward :activate
  end
end
