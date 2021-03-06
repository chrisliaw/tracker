class Project < ActiveRecord::Base
  attr_accessible :desc, :name, :short_name, :state, :created_by, :identifier, :created_at, :updated_at, :code, :category_tags
  has_many :develements
  #has_many :features, :class_name => "Develement" , :conditions => "develement_type_id = 1"
  #has_many :enhancements, :class_name => "Develement", :conditions => "develement_type_id = 2"
  has_many :issues
  #has_many :schedules, :order => :name
  has_many :variances, :order => :name
	has_many :attachments

  has_many :version_controls, :as => :versionable
  has_many :schedules, :as => :schedulable
  has_many :commits, :as => :committable

	has_many :project_packages
	has_many :packages, :through => :project_packages

  validates :code, :presence => true, :uniqueness => { :case_sensitive => false } #, :on => :create

	def open_schedules
		Schedule.where(["schedulable_type = 'Project' and schedulable_id = ? and schedules.state != 'released'", self.id])
	end

	def active_schedules
		Schedule.where(["schedulable_type = 'Project' and schedulable_id = ? and (schedules.state = 'active' or schedules.state = 'stabilizing')", self.id])
	end

	def active_version_controls
		VersionControl.where(["versionable_type = 'Project' and versionable_id = ? and version_controls.state = 'active'", self.id])
	end

	def released_schedules
		Schedule.where(["schedulable_type = 'Project' and schedulable_id = ? and schedules.state = 'released'", self.id])
	end

	def self.active_projects
		Project.where("state = 'active'").order(:name)
	end
	
	def self.tags
		@tags = []
		Project.all.each do |p|
			tag = p.category_tags
			if tag != nil and not tag.empty?
				tag.split(",").each do |t|
					#@tags << t.titleize if not @tags.include?(t.titleize)
					@tags << t.strip if not @tags.include?(t.strip)
				end
			end
		end
		@tags.sort
	end

  distributable

  stateful :initial => :evaluation

  transform :evaluation => :active do
    forward :activate
    backward :reevaluate
  end

  transform :active => :kiv do
    forward :on_hold
    backward :reactivate
  end

  transform :evaluation => :kiv do
    forward :on_hold
    backward :reevaluate
  end

  transform :active => :end_of_life do
    forward :EOL#, :guard => Proc.new { |rec| rec.name == "Jack2" }
    #forward :expired, :guard => Proc.new { |rec| rec.name == "Jack" }
    backward :reactivate
  end

  transform :end_of_life => :archived do
    forward :archive
  end
end
