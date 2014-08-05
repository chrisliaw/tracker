class AddProjectTag < ActiveRecord::Migration
  def up
		add_column :projects, :category_tags, :string 
  end

  def down
		remove_column :projects, :category_tags
  end
end
