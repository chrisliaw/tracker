class CreateDevelements < ActiveRecord::Migration
  def change
    create_table :develements do |t|
      t.string    :identifier # support distributed key
      t.string    :project_id
      t.string    :name
      t.text      :desc
      t.string    :code       # common key to differentiate distributed data creation
      t.string    :state
      t.integer   :develement_type_id
      t.string    :schedule_id
      t.string    :created_by # this field will be email address of creator
      t.string    :variance_parent_id   # to support extraction of develements of a particular variance of a single develement
      t.string    :variance_id
      t.string    :data_hash  # this value will be sent to another node for comparison
			t.string		:parent_id
      t.timestamps
    end
  end
end
