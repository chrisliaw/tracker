class EnableDvcsConfigDistributable < ActiveRecord::Migration
  def up
		add_column :dvcs_configs, :identifier, :string
		add_column :dvcs_configs, :data_hash, :string
		change_column :version_controls, :upstream_vcs_class, :string
		change_column :version_controls, :vcs_class, :string	
  end

  def down
		remove_column :dvcs_configs, :identifier
		remove_column :dvcs_configs, :data_hash
		change_column :version_controls, :upstream_vcs_class, :integer
		change_column :version_controls, :vcs_class, :integer
  end
end
