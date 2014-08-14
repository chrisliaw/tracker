class SyncServiceController < ApplicationController
	
  def login
  end

  def index

  end

  def download
  end

  def upload
  end

	def sync
		ops = params[:operation]
		nodeID = params[:node_id]		
		syncHistory = SyncLogs.where(["node_id = ?",nodeID])
		@distRec = Distributable::DistributableRecord.new
		# operation: 1 - add, 2 - edit, 3 - delete
		# Note the sync does not push history to another node. History is always local. Only data will be pushed to another node
		if syncHistory.length == 0
			# never come here before
			cutOffChange = ChangeLogs.last
			if cutOffChange != nil
				changesTbl = ChangeLogs.where(["id <= ?",cutOffChange.id]).uniq.pluck('table_name')
				changesTbl.each do |tbl|
					changesKey = ChangeLogs.where(["id <= ? and table_name = ?",cutOffChange.id,tbl]).uniq.pluck(:key)
					changesKey.each do |k|
						add = ChangeLogs.where(["id <= ? and table_name = ? and key = ? and operation = 1",cutOffChange.id,tbl,k])
						edit = ChangeLogs.where(["id <= ? and table_name = ? and key = ? and operation = 2",cutOffChange.id,tbl,k])
						del = ChangeLogs.where(["id <= ? and table_name = ? and key = ? and operation = 3",cutOffChange.id,tbl,k])

						rec = eval("#{tbl.classify}.find('#{k}')")
						if rec != nil
							if add.length > 0 and add.length == del.length
								# record add here and deleted (status changed, not physical remove) here...ignore the record
							elsif add.length > del.length 
								# record added here but not deleted
								# Ignore edit operation after that since remote node doesn't have this record anyway
								@distRec.add_new_record(rec)
							elsif del.length > add.length
								# record deleted (status changed, not physical remove) only
								@distRec.add_deleted_record(tbl,k)
							else
								@changed = []
								edit.each do |er|
									changedFields = JSON.parse(er.changed_fields) if er.changed_fields != nil
									@changed = @changed | changedFields  # remove duplicates field name
								end
								@distRec.add_edited_record(rec,@changed)
							end
						else
							# deleted record from database will fall under here
							logger.warn("Can not find record from table #{tbl} with id #{k} to sync. Probably deleted?")
							if add.length == del.length
								# record add here and deleted (status changed, not physical remove) here...ignore the record
							elsif del.length > add.length
								@distRec.add_deleted_record(tbl,k)
							end
						end
					end

				end # end changed table loop
			end # end if cutOffChange != nil
		end

		respond_to do |format|
			#format.json { render json: YAML.dump(@distRec) }
			format.json { render json: @distRec }
		end	
	end
end
