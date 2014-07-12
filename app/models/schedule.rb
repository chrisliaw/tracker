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

  transform :active => :released do
    forward :release
  end
end
