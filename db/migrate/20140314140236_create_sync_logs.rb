class CreateSyncLogs < ActiveRecord::Migration
  def change
    create_table :sync_logs do |t|
      t.string  :node_id
      t.string  :user_id
      t.integer :last_change_log_id
      t.string  :last_sync_from
      t.integer :direction   # 1 : push ; 2 : pull
      t.timestamps
    end
  end
end
