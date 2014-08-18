class CreateSyncHistories < ActiveRecord::Migration
  def change
    create_table :sync_histories do |t|
      t.string 	:node_id
      t.string 	:sync_session_id
      t.text 		:sync_data
      t.integer :status

      t.timestamps
    end
  end
end
