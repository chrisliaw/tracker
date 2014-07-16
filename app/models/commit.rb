class Commit < ActiveRecord::Base
  attr_accessible :committable_id, :committable_type, :identifier, :vcs_affected_files, :vcs_diff, :vcs_info, :vcs_reference

  #distributable
  belongs_to :committable, :polymorphic => true
end
