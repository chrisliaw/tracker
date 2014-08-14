
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

		def add_deleted_record(table,key)
			if @delRec[table] == nil
				@delRec[table] = []
			end
			@delRec[table] << key
		end

		def add_edited_record(rec,changes)
			tblName = rec.class.table_name
			if @changedRec[tblName] == nil
				@changedRec[tblName] = []
			end
			@changedRec[tblName] << changes
		end
	end
end
