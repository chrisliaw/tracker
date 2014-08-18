class SyncHistory < ActiveRecord::Base
  attr_accessible :node_id, :status, :sync_data, :sync_session_id

	COMPLETED = 0
	INCOMPLETE = 1
end
