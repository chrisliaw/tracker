class CreateChangeLogs < ActiveRecord::Migration
  def change
    create_table :change_logs do |t|
      t.string :table
      t.string :key
      t.integer :operation

      t.timestamps
    end
  end
end
