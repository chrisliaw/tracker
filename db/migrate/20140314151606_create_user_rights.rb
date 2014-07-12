class CreateUserRights < ActiveRecord::Migration
  def change
    create_table :user_rights do |t|
      t.integer :user_id
      t.string :domain  # such as project table
      t.string :right

      t.timestamps
    end
  end
end
