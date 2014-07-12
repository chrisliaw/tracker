load "event_action.rb"

class TestEventAction
	attr_accessor :state
	extend Antrapol::EventAction

	stateful :initial => :evaluate	

	transform :evaluating => :active do
		forward :activate
	end

	transform :active => :kiv do
		forward :on_hold
		forward :killed, :guard => Proc.new { |d| puts "Killed guard" }
		backward :reactivate, :guard => Proc.new { |p| puts "Reactivate guard" }
	end

	transform :standby => :active do
		forward :activate
		backward :reconsider
	end
end
