class Attachment < ActiveRecord::Base
  attr_accessible :attachable_id, :attachable_type, :attachment_class, :project_id, :url

	ATT_CLS_MANAGED_TEST_SCRIPT = 1
	ATT_CLS_REFERENCED_TEST_SCRIPT = 2

	belongs_to :project
	belongs_to :attachable, :polymorphic => true

end
