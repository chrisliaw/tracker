class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string 	:attachable_type
      t.string 	:attachable_id
			# 1 - managed_test_script, 2 - Linked_test_script, 3 - others
      t.integer :attachment_class
      t.string 	:url
      t.string 	:project_id

      t.timestamps
    end
  end
end
