class UpgradeUserTable < ActiveRecord::Migration
  def up
		add_column :users, :state, :string
		add_column :users, :rights, :string
		remove_column :users, :status
		add_column :users, :groups, :string
		rename_column :users, :cert_validation_token, :validation_token
  end

  def down
		remove_column :users, :state
		remove_column :users, :rights
		add_column :users, :status, :integer
		remove_column :users, :groups
		rename_column :users, :validation_token, :cert_validation_token
  end
end
