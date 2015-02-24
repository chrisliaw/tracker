class CreateProjectPackages < ActiveRecord::Migration
  def change
    create_table :project_packages do |t|
			t.string	:identifier
      t.string  :project_id
      t.string  :package_id
			t.string	:data_hash

      t.timestamps
    end
  end
end
