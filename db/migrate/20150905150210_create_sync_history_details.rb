class CreateSyncHistoryDetails < ActiveRecord::Migration
  def change
    create_table :sync_history_details do |t|
      t.integer :sync_history_id
      t.string :table_name
      t.string :identifier
      t.integer :operation
      t.integer :status
			t.string	:notes
			t.integer	:crash_flag

      t.timestamps
    end
  end
end
