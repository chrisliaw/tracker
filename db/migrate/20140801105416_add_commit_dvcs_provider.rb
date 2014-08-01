class AddCommitDvcsProvider < ActiveRecord::Migration
  def up
		add_column :commits, :dvcs_provider, :string
  end

  def down
		remove_column :commits, :dvcs_provider
  end
end
