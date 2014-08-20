class SyncMerge < ActiveRecord::Base
  attr_accessible :changeset, :distributable_id, :distributable_type, :status, :sync_history_id

	MERGED = 10
	CRASHED = 20

	belongs_to :sync_history
end
