
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
			@newRec = []
			@delRec = []
			@changedRec = []
		end

		def add_new_record(rec)
			@newRec << rec
		end

		def add_deleted_record(table,key)
			@delRec << DeletedRecord.new(table,key)
		end

		def add_edited_record(rec,changes)
			@changedRec << ChangedRecord.new(rec,changes)
		end
	end
end
