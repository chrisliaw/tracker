class Variance < ActiveRecord::Base
  attr_accessible :created_by, :desc, :name, :project_id, :state
  belongs_to :project
  has_many :version_controls, :as => :versionable
  has_many :schedules, :as => :schedulable

  has_many :develements
	has_many :issues

  validates :name, :presence => true

	def active_schedules
		Schedule.where(["schedulable_type = 'Variance' and schedulable_id = ? and schedules.state = 'active'", self.id])
	end

	def active_version_controls
		VersionControl.where(["versionable_type = 'Variance' and versionable_id = ? and version_controls.state = 'active'", self.id])
	end

  distributable

  stateful :initial => :evaluation

  transform :evaluation => :active do
    forward :activate
    backward :on_hold
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
    forward :EOL
    backward :reactivate
  end

  transform :end_of_life => :archived do
    forward :archive
  end

end
