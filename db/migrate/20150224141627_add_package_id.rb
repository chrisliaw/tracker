class AddPackageId < ActiveRecord::Migration
  def up
		add_column :develements, :package_id, :string
  end

  def down
		remove_column :develements, :package_id
  end
end
