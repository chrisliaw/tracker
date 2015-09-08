class SyncHistoryDetail < ActiveRecord::Base
  attr_accessible :identifier, :operation, :status, :sync_history_id, :table_name, :notes, :crash_flag

	belongs_to :sync_history

	NEW_RECORD = 1
	UPDATE_RECORD = 2
	DEL_RECORD = 3

	NO_CRASH = 10
	CRASHED = 11
	IGNORED = 99
end
