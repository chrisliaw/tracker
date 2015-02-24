class CreatePackages < ActiveRecord::Migration
  def change
    create_table :packages do |t|
			t.string	:identifier
      t.string 	:name
			t.string	:data_hash

      t.timestamps
    end
  end
end
