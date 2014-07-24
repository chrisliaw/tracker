class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string  :identifier
      t.string  :project_id
      t.string  :name
      t.text    :desc
      t.string  :code
      t.string  :state
      t.integer :issue_type_id
      t.string  :schedule_id
      t.string  :created_by
			t.string	:variance_parent_id
			t.string	:variance_id
      t.string  :data_hash
			t.string	:parent_id
      t.timestamps
    end
  end
end
