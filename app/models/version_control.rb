class VersionControl < ActiveRecord::Base
  attr_accessible :created_by, :name, :updated_by, :upstream_vcs_class, :upstream_vcs_path, :vcs_class, :vcs_path, :versionable_id, :versionable_type, :state, :pushable_repo, :upstream_vcs_branch, :vcs_branch

  belongs_to :versionable, :polymorphic => true

  validates :name, :presence => true
  #validates :upstream_vcs_path, :presence => true, :if => lambda { self.pushable_repo == nil or self.pushable_repo == 0 or (self.vcs_path == nil or self.vcs_path.empty?) }
  validates :upstream_vcs_path, :presence => true, :if => lambda { self.vcs_path == nil or self.vcs_path.empty? }
  validates :vcs_path, :presence => true, :if => lambda { self.pushable_repo == 1 or self.upstream_vcs_path == nil or self.upstream_vcs_path.empty? }

	distributable
  stateful :initial => :active

  transform :active => :inactive do
    forward :inactivate
    backward :activate
  end
end
