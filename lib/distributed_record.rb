
module Distributable

	class ChangedRecord
		attr_accessor :rec, :changes
		def initialize(rec,changes)
			@rec = rec
			@changes = changes
		end
	end

	class DeletedRecord
		attr_accessor :table, :key
		def initialize(table,key)
			@table = table
			@key = key
		end
	end

	class DistributableRecord
		attr_accessor :newRec, :delRec, :changedRec
		def initialize
			@newRec = {}
			@delRec = {}
			@changedRec = {}
		end

		def add_new_record(rec)
			tblName = rec.class.table_name
			if @newRec[tblName] == nil
				@newRec[tblName] = []
			end
			@newRec[tblName] << rec
		end

		def new_record_count
			@cnt = 0
			@newRec.each do |k,v|
				@cnt = @cnt + v.length
			end
			@cnt
		end

		def add_deleted_record(table,key)
			if @delRec[table] == nil
				@delRec[table] = []
			end
			@delRec[table] << key
		end

		def deleted_record_count
			@cnt = 0
			@delRec.each do |k,v|
				@cnt = @cnt + v.length
			end
			@cnt
		end

		def add_edited_record(rec,changes)
			tblName = rec.class.table_name
			if @changedRec[tblName] == nil
				@changedRec[tblName] = []
			end
			changeFields = {}
			changes.each do |c|
				changeFields[c] = eval("rec.#{c}") 
			end
			@changedRec[tblName] << [rec.identifier,changeFields]
		end

		def edited_record_count
			@cnt = 0
			@changedRec.each do |k,v|
				@cnt = @cnt + v.length
			end
			@cnt
		end
	end
end
