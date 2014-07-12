class CreateCommits < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.string :committable_type
      t.string :committable_id
      t.string :identifier
      t.string :vcs_reference
      t.string :vcs_diff
      t.string :vcs_info
      t.string :vcs_affected_files

      t.timestamps
    end
  end
end
