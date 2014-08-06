class EnableVersionControlTableDistributable < ActiveRecord::Migration
  def up
		add_column :version_controls, :identifier, :string
		add_column :version_controls, :data_hash, :string
  end

  def down
		remove_column :version_controls, :identifier
		remove_column :version_controls, :data_hash
  end
end
