class CreateVersionControlBranches < ActiveRecord::Migration
  def change
    create_table :version_control_branches do |t|
      t.string :identifier	# Distributable
      t.string :data_hash		# Distributable
      t.string :project_status
      t.string :vcs_branch
      t.string :version_control_id

      t.timestamps
    end
  end
end
