class CreateUsers < ActiveRecord::Migration
  def change
    # mostly data in this table is allow push/pull request from another nodes
    create_table :users do |t|
      t.string  :login  # this must be email then...
      t.string  :cert
      t.string  :cert_validation_token
      t.integer :status, :default => 1

      t.timestamps
    end

    #User.create(
    #  :login => "dev@test.com",
    #  :name => "Developer",
    #  :pass => "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    #)
  end
end
