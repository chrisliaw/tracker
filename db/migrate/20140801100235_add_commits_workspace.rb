class AddCommitsWorkspace < ActiveRecord::Migration
  def up
		add_column :commits, :repository_url, :string	
  end

  def down
		remove_column :commits, :repository_url
  end
end
