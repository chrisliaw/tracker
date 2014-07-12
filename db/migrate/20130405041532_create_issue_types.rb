class CreateIssueTypes < ActiveRecord::Migration
  def change
    create_table :issue_types do |t|
      t.string  :name
      t.text    :desc
      t.string  :state

      t.timestamps
    end

    IssueType.create(
      :name => "Bug",
      :desc => "Show stopper which stops the system or giving the output as it should"
    )

    IssueType.create(
      :name => "Defect",
      :desc => "Inconsistency with requirement or expectation however does not stop the system or produce errornous output"
    )

    IssueType.create(
      :name => "Enhancement",
      :desc => "Suggestion or minor touch up on the system but does not affect functionality of the system"
    )
  end
end
