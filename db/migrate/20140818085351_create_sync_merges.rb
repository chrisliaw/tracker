class CreateSyncMerges < ActiveRecord::Migration
  def change
    create_table :sync_merges do |t|
			t.integer	:sync_history_id
      t.string 	:distributable_type
      t.string 	:distributable_id
      t.text 		:changeset
      t.integer :status

      t.timestamps
    end
  end
end
