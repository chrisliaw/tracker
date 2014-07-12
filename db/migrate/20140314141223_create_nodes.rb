class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string :identifier
      t.timestamps
    end
  end
end
