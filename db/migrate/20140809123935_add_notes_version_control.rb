class AddNotesVersionControl < ActiveRecord::Migration
  def up
		add_column :version_controls, :notes, :text
  end

  def down
		remove_column :version_controls, :notes
  end
end
