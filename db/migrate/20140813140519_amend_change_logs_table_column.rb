class AmendChangeLogsTableColumn < ActiveRecord::Migration
  def up
		rename_column :change_logs, :table, :table_name
		add_column :change_logs, :changed_fields, :string
  end

  def down
		rename_column :change_logs, :table_name, :table
		remove_column :change_logs, :changed_fields
  end
end
