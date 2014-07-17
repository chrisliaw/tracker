class Commit < ActiveRecord::Base
  attr_accessible :committables_id, :committables_type, :identifier, :vcs_affected_files, :vcs_diff, :vcs_info, :vcs_reference

  #distributable
  belongs_to :committable, :polymorphic => true
end
