class EnableDvcsConfigDistributable < ActiveRecord::Migration
  def up
		add_column :dvcs_configs, :identifier, :string
		add_column :dvcs_configs, :data_hash, :string
  end

  def down
		remove_column :dvcs_configs, :identifier
		remove_column :dvcs_configs, :data_hash
  end
end
