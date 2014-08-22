class EnableCommitDistributable < ActiveRecord::Migration
  def up
		add_column :commits, :data_hash, :string
  end

  def down
		remove_column :commits, :data_hash
  end
end
