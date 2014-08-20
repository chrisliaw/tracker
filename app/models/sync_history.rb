class SyncHistory < ActiveRecord::Base
  attr_accessible :node_id, :status, :sync_data, :sync_session_id

	COMPLETED = 0
	INCOMPLETE = 1

	has_many :sync_merges
	def pending_sync_merges
		@pending = []
		self.sync_merges.each do |sm|
			@pending << sm if sm.status == SyncMerge::CRASHED
		end
		@pending
	end
end
