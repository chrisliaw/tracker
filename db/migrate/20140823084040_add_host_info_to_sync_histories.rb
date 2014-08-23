class AddHostInfoToSyncHistories < ActiveRecord::Migration
  def change
		add_column :sync_histories, :host, :string
  end
end
