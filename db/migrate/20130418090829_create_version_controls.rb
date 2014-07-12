class CreateVersionControls < ActiveRecord::Migration
  def change
    create_table :version_controls do |t|
      t.string  :name
      t.string  :versionable_type
      t.string  :versionable_id
      t.integer :upstream_vcs_class
      t.string  :upstream_vcs_path
      t.string  :upstream_vcs_branch
      t.integer :vcs_class
      t.string  :vcs_path
      t.string  :vcs_branch
      t.string  :created_by
      t.string  :updated_by
      t.string  :state
      t.integer :pushable_repo, :default => 0

      t.timestamps
    end
  end
end
