class CreateSyncHistories < ActiveRecord::Migration
  def change
		# Temporary local storage after pull from remote node
		# to allow all sync-merge operation to be done 
		# and also allow retry if there are errors
    create_table :sync_histories do |t|
      t.string 	:node_id
      t.string 	:sync_session_id
      t.text 		:sync_data
      t.integer :status

      t.timestamps
    end
  end
end
