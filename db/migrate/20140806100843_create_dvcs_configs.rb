class CreateDvcsConfigs < ActiveRecord::Migration
  def change
    create_table :dvcs_configs do |t|
      t.string :name
      t.string :path

      t.timestamps
    end
  end
end
