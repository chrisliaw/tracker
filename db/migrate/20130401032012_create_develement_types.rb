class CreateDevelementTypes < ActiveRecord::Migration
  def change
    create_table :develement_types do |t|
      t.string  :name
      t.text    :desc
      t.string  :state

      t.timestamps
    end

    DevelementType.create(
      :name => "Feature",
      :desc => "Development element is a new feature"
    )

    DevelementType.create(
      :name => "Enhancement",
      :desc => "Development element is enhancement"
    )

    DevelementType.create(
      :name => "Task",
      :desc => "Develement element is task"
    )

  end
end
