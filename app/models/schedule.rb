class Schedule < ActiveRecord::Base
  attr_accessible :created_by, :desc, :name, :schedulable_id, :schedulable_type, :state

  # assistance field
  attr_accessible :req_src
  attr_accessor :req_src

  validates :name, :presence => true
  #belongs_to :project
  belongs_to :schedulable, :polymorphic => true
  has_many :develements
  has_many :issues

  distributable 

  stateful :initial => :planning

  transform :planning => :active do
    forward :activate
    backward :replan
  end

  transform :active => :inactive do
    forward :on_hold
    backward :activate
  end

	# once released, all changes should be made in branches (stabilization)
	# All fixes shall be based on this branch
  transform :active => :released do
    forward :release
  end

	transform :released => :eol do
		forward :end_of_life
	end

	transform :eol => :archived do
		forward :archive
	end
end
