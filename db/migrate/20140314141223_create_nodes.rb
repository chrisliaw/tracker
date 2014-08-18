class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string :identifier
      t.timestamps
    end

		Node.create(
			:identifier => Digest::SHA1.hexdigest("#{SecureRandom.uuid}")
		)
  end
end
