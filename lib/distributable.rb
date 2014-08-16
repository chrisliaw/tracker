
module Distributable
  module ClassMethods
    def distributable(opts = {})

      options = {
        distribution_key: :identifier,
        hash_field_name: :data_hash,
        skippedCols: %W(created_at updated_at created_by updated_by id),
        hash_list: [:identifier],   # force user to give the list as dynamically generated the list might not fit into the same sequence
        change_log_table: :ChangeLogs
      }

      options.update(opts) if opts.is_a?(Hash)
      
      self.primary_key = options[:distribution_key].to_sym

      before_create :generate_identifier 
      after_save :generate_hash  # log new and update changes inside this 

      #after_create :log_new_change
      #after_update :log_update_change
      after_destroy :log_destroy_change

      validates options[:distribution_key].to_sym, :uniqueness => true

      @@opts = options
    end

    def options
      @@opts
    end

  end

  module InstanceMethods
    def distributable?
      true
    end

    def log_new_change
      log = eval("#{self.class.options[:change_log_table].to_s}.new")
      log.table_name = self.class.table_name   # use classify method to get the proper table name back
      log.key = self.send "#{self.class.options[:distribution_key]}"
      log.operation = 1
      log.save
    end

    def log_update_change
			if self.changed?
				log = eval("#{self.class.options[:change_log_table]}.new")
				log.table_name = self.class.table_name
				log.key = self.send "#{self.class.options[:distribution_key]}"
				#changedFields = self.changed
				#filtered = self.changed & self.class.options[:skippedCols] 
				#log.changed_fields = (changedFields - filtered).to_json
				changedFields = self.changed.delete_if { |c| self.class.options[:skippedCols].include?(c) }
				log.changed_fields = changedFields.to_json
				log.operation = 2
				log.save
			end
    end

    def log_destroy_change
      log = eval("#{self.class.options[:change_log_table]}.new")
      log.table_name = self.class.table_name
      log.key = self.send "#{self.class.options[:distribution_key]}"
      log.operation = 3
      log.save
    end

    def generate_identifier
			if self.identifier != nil and not self.identifier.empty?
				# Guard here is to allow the identifier use the remote identifier without re-generating a new one
			else
				while true
					begin
						while true
							#self.identifier = Digest::SHA1.hexdigest "#{Time.now.to_f}#{SecureRandom.random_number}"
							self.send("#{self.class.options[:distribution_key]}=", Digest::SHA1.hexdigest("#{SecureRandom.uuid}"))
							#self.identifier = Digest::SHA1.hexdigest "#{SecureRandom.uuid}"
							res = self.class.find :first, :conditions => ["identifier = ?",self.identifier]
							break if res == nil # break if no duplication found
						end
						#self.save!
						break
					rescue Exception => e
						p e
						retry
					end
				end
			end
    end

    def generate_hash
      if @hash_generated == nil or @hash_generated != true

        #if self.class.options[:hash_list] != nil and self.class.options[:hash_list].is_a?(Array)
        #  data = []
        #  self.class.options[:hash_list].each do |c|
        #    data << self.send(c)
        #  end
        #  self.send("#{self.class.options[:hash_field_name]}=",Digest::SHA1.hexdigest("#{data.join}"))
        #  @hash_generated = true # make sure second time call it stops and not into infinite loop
        #  #self.data_hash = Digest::SHA1.hexdigest "#{data.join}"
        #  self.save!
        #end

      #else
        if self.send("#{self.class.options[:hash_field_name]}") == nil
          log_new_change
        else
          log_update_change
        end

        cols = []
        self.class.columns.each do |c|
          cols << c.name
        end
        sortedCols = cols.sort
        data = []
        sortedCols.each do |c|
          data << self.send(c.to_sym) if self.class.options[:skippedCols] != nil and !self.class.options[:skippedCols].include?(c)
        end
        self.send("#{self.class.options[:hash_field_name]}=",Digest::SHA1.hexdigest("#{data.join}"))
        @hash_generated = true # make sure second time call (save statement after this line) it stops and will not fall into infinite loop
        self.save!
      end
    end

  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
#ActiveRecord::Base.extend Distributable
Distributable.included ActiveRecord::Base

