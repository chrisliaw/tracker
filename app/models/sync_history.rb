class SyncHistory < ActiveRecord::Base
  attr_accessible :node_id, :status, :sync_data, :sync_session_id

	COMPLETED = 0
	INCOMPLETE = 1

	has_many :sync_merges
	has_many :sync_history_details
	def self.pending_sync_merges(node_id)
		@pending = []
		hist = SyncHistory.where(["node_id = ?",node_id])
		hist.each do |h|
			h.sync_merges.each do |sm|
				@pending << sm if sm.status == SyncMerge::CRASHED
			end
		end	
		@pending
	end
end
