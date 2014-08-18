class SyncLogs < ActiveRecord::Base
  attr_accessible :direction, :last_change_log_id, :node_id, :user_id, :last_sync_from

	LOCAL_REF = 10
	REMOTE_REF = 20

end
