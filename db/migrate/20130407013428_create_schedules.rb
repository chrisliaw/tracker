class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.string  :identifier
      t.string  :schedulable_type
      t.string  :schedulable_id
      t.string  :name
      t.text    :desc
      t.string  :state
      t.string  :data_hash
      t.string  :created_by
      t.timestamps
    end
  end
end
