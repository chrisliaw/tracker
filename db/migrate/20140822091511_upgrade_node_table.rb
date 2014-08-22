class UpgradeNodeTable < ActiveRecord::Migration
  def up
		add_column :nodes, :state, :string
		add_column :nodes, :rights, :string
		add_column :nodes, :submitted_by, :string
  end

  def down
		remove_column :nodes, :state
		remove_column :nodes, :rights
		remove_column :nodes, :submitted_by
  end
end
