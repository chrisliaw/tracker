
module Antrapol
	module EventAction
		# Activate the module which embed the extra functions into target class
		def stateful(options = {})
			class_eval do
				extend Antrapol::ClassMethod
				include Antrapol::InstanceMethod
				
				self.class_variable_set(:@@_states,[])
				self.class_variable_set(:@@initial,options[:initial])
				self.class_variable_set(:@@event_states_table,{})
			end	
		end

		class Event
      attr_accessor :new_events
			def initialize(states,es_table)
        # mapping of { :event => [{:transition => {:from_state => :to_state}, :guard => Proc..., },
        #                         {:transition => {:from_state => :to_state}, :guard => Proc...,}
        #                         ] }
        @es_table = es_table
				@states = states					
        @new_events = []
			end

			def forward(event,opts={})
				#puts "Forward Event : #{event}"
				#puts "States : #{@states}"
        if @es_table[event] == nil
          @new_events << event
          @es_table[event] = []
        end
        @es_table[event] << { :transition => { @states.keys[0] => @states.values[0] }, :guard => opts[:guard] }
        #p @event_states
			end

			def backward(event,opts={})
				#puts "Backward Event : #{event}"
				#puts "States : #{@states}"
        if @es_table[event] == nil
          @new_events << event
          @es_table[event] = []
        end
        @es_table[event] << { :transition => { @states.values[0] => @states.keys[0] }, :guard => opts[:guard] }
        #p @event_states
			end

      def fire_event(event,record)
        current = record.state.to_sym
        #p record.event_states_table[event]
        @success = false
        #record.event_states_table[event].each do |evt|
        @es_table[event].each do |evt|
          if evt[:transition].keys[0] == current
            if evt[:guard] != nil
              if evt[:guard].call(record)
                record.state = evt[:transition].values[0].to_s if evt[:transition].keys[0] == current
                record.save   # to comply to '!' notication of the method
                @success = true
                break # break here to honour the first guard found and return true
              end
            else
              record.state = evt[:transition].values[0].to_s if evt[:transition].keys[0] == current
              record.save   # to comply to '!' notication of the method
              @success = true
            end
          end
        end
        @success
      end
		end

	end
	
	# Embed class level method into the class
	module ClassMethod
		def transform(states,opts={},&block)
			#puts "From state : #{states.keys[0]}"
			_states = class_variable_get :@@_states
			event_states_table = class_variable_get :@@event_states_table
			_states << states.keys[0].to_sym if !_states.include?(states.keys[0].to_sym)
			#puts "To state : #{states.values[0]}"
			_states << states.values[0].to_sym if !_states.include?(states.values[0].to_sym)
			e = Antrapol::EventAction::Event.new(states,event_states_table)
			e.instance_eval(&block) if block
			e.new_events.each do |evt|
				define_method("#{evt}!") { 
					e.fire_event(evt,self) 
				}
			end
			#puts "Event states table"
			#p event_states_table
		end

		def states
			class_variable_get :@@_states
		end

	end
	
	# Embed instance level method into the class
	module InstanceMethod
    def possible_events
      @current = self.state.to_sym
      @events = []
			event_states_table = self.class.class_variable_get :@@event_states_table
      event_states_table.keys.each do |k|
        event_states_table[k].each do |s|
          if s[:transition].keys[0] == @current and !@events.include?(k)
            if s[:guard] != nil
              if s[:guard].call(self)
                @events << k
              end
            else
              @events << k
            end
          end
        end
      end
      @events
    end 

    def initialize(*arg)
      super(*arg)
      self.state = self.class.class_variable_get :@@initial
			self.state = self.state.to_s if self.state != nil
    end
	end
end
