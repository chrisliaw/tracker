class AddDirectionSyncHistory < ActiveRecord::Migration
  def up
		add_column :sync_histories, :direction, :integer
  end

  def down
		remove_column :sync_histories, :direction
  end
end
