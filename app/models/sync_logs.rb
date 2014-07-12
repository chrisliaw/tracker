class SyncLogs < ActiveRecord::Base
  attr_accessible :direction, :last_change_log_id, :node_id
end
