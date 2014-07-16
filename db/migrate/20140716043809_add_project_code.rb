class AddProjectCode < ActiveRecord::Migration
  def up
		add_column :projects, :code, :string
  end

  def down
		remove_column :projects, :code
  end
end
