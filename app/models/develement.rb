class Develement < ActiveRecord::Base
  attr_accessible :code, :desc, :develement_type_id, :name, :project_id, :state, :schedule_id, :identifier, :created_by, :variance_parent_id, :variance_id, :package_id
  belongs_to :develement_type
  belongs_to :project
  belongs_to :schedule
  belongs_to :variance

	has_many :attachments, :as => :attachable
  has_many :commits, :as => :committables, :order => :created_at

  validates :name, :presence => true
	validates_uniqueness_of :name, :scope => :project_id
	belongs_to :package

  distributable
  acts_as_tree :foreign_key => "variance_parent_id", :parent_name => "variance_parent", :children_name => "variance_children", :prefix => "variance_" 
	acts_as_tree

  after_create :update_code_and_id

  def update_code_and_id
		# id only available after create...
		# Note this id is not the distributed ID, it is the standard rails model id
		self.reload
		code = "%05d" % self._id
		self.code = "#{self.project.code}/Dev/#{code}"
		self.save!
  end

	def user_code
		if self.code != nil and not self.code.empty?
			sp = self.code.split("/")
			sp2 = sp[1..-1]
			sp2.join("/")
		else
			""
		end
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
