
class Node < ActiveRecord::Base
  attr_accessible :identifier
  attr_accessor :name, :email, :orgName, :orgUnit, :state, :country, :id_path, :pass, :pass_confirmation
end
