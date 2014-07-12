class Issue < ActiveRecord::Base
  attr_accessible :code, :desc, :issue_type_id, :name, :project_id, :state, :schedule_id, :identifier, :created_by
  belongs_to :issue_type
  belongs_to :project
  belongs_to :schedule
	belongs_to :variance
  has_many :version_controls, :as => :versionable
  has_many :commits, :as => :committables

  validates :name, :presence => true

  distributable 
  acts_as_tree :foreign_key => "variance_parent_id", :parent_name => "variance_parent", :children_name => "variance_children", :prefix => "variance_" 
	acts_as_tree

  after_create :create_code_and_id
  def create_code_and_id
    #code = "%05d" % self.id
    #self.code = "#{self.created_by.downcase}/#{self.project.short_name}/I/#{code}"
    #data = "#{self.created_by.downcase}#{self.code}#{Time.now.to_f}"
    #self.identifier = Digest::SHA1.hexdigest data
    #self.save!
  end

  stateful :initial => :open

  transform :open => :active do
    forward :assigned
    backward :unassigned
  end

  transform :active => :resolved do
    forward :resolve
    backward :reactive
  end

  transform :resolved => :fix_verified do
    forward :fix_verified
  end

  transform :fix_verified => :active do
    forward :fix_rejected
  end

  transform :fix_verified => :closed do
    forward :close
  end
  
  transform :active => :ignored do
    forward :ignore
    backward :reactivate
  end

end
