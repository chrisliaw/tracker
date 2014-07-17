class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string  :identifier
      t.string  :name
      t.text    :desc
      t.text    :state
      t.string  :created_by
      t.string  :data_hash
      t.timestamps
    end
  end
end
