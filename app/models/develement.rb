class Develement < ActiveRecord::Base
  attr_accessible :code, :desc, :develement_type_id, :name, :project_id, :state, :schedule_id, :identifier, :created_by, :variance_parent_id, :variance_id
  belongs_to :develement_type
  belongs_to :project
  belongs_to :schedule
  belongs_to :variance

  has_many :commits, :as => :committables

  validates :name, :presence => true

  distributable
  acts_as_tree :foreign_key => "variance_parent_id", :parent_name => "variance_parent", :children_name => "variance_children", :prefix => "variance_" 
	acts_as_tree

  after_create :update_code_and_id

  def update_code_and_id
    #code = "%05d" % self.id
    #self.code = "#{self.created_by.downcase}/#{self.project.short_name}/D/#{code}"
    #data = "#{self.created_by.downcase}#{self.code}#{Time.now.to_f}"
    #self.identifier = Digest::SHA1.hexdigest data
    #self.save!
  end

  stateful :initial => :open

  transform :open => :active do
    forward :activate
  end

  transform :active => :implemented do
    forward :done
		backward :test_failed
  end

  transform :implemented => :tested do
    forward :verified
  end

  transform :tested => :closed do
    forward :close
  end

  transform :active => :rejected do
    forward :reject
    backward :reactivate
  end

end
