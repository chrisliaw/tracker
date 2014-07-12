class CreateVariances < ActiveRecord::Migration
  def change
    create_table :variances do |t|
      t.string  :identifier
      t.string  :project_id
      t.string  :name
      t.text    :desc
      t.string  :state
      t.string  :created_by
      t.string  :data_hash
      t.timestamps
    end
  end
end
