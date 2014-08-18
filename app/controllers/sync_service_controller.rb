class SyncServiceController < ApplicationController
	
  def login
		nodeID = params[:node_id]
		node = Node.first
		# Check if the node ID is in the list
		nodeSess = SecureRandom.uuid
		Struct.new("LoginStatus",:status, :status_message, :token, :server_id)
		# TODO: nodeSess shall be encrypted with presented cert
		retData = Struct::LoginStatus.new(true,"Authenticated",nodeSess,node.identifier)
		respond_to do |format|
			format.json { render json: retData }
		end
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
				changesTbl = ChangeLogs.where(["id between ? and ?",0,cutOffChange.id]).uniq.pluck('table_name')
				changesTbl.each do |tbl|
					changesKey = ChangeLogs.where(["id between ? and ? and table_name = ?",0,cutOffChange.id,tbl]).uniq.pluck(:key)
					changesKey.each do |k|
						add = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 1",0,cutOffChange.id,tbl,k])
						edit = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 2",0,cutOffChange.id,tbl,k])
						del = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 3",0,cutOffChange.id,tbl,k])

						rec = eval("#{tbl.classify}.where([\"identifier = ?\",'#{k}'])")
						if rec.length > 0
							if add.length > 0 and add.length == del.length
								# record add here and deleted (status changed, not physical remove) here...ignore the record
							elsif add.length > del.length 
								# record added here but not deleted
								# Ignore edit operation after that since remote node doesn't have this record anyway
								@distRec.add_new_record(rec[0])
							elsif del.length > add.length
								# record deleted (status changed, not physical remove) only
								@distRec.add_deleted_record(tbl,k)
							else
								@changed = []
								edit.each do |er|
									changedFields = JSON.parse(er.changed_fields) if er.changed_fields != nil
									@changed = @changed | changedFields  # remove duplicates field name
								end
								@distRec.add_edited_record(rec[0],@changed)
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

				sl = SyncLogs.new
				sl.node_id = nodeID
				sl.last_change_log_id = cutOffChange.id
				sl.save

			else
				# no ChangeLogs record means there is no changes being made...
			end # end if cutOffChange != nil

		else
			# this node came here before...
			cutOffChange = ChangeLogs.last
			if cutOffChange != nil and syncHistory[0].last_change_log_id != cutOffChange.id
				changesTbl = ChangeLogs.where(["id between ? and ?",syncHistory[0].last_change_log_id+1,cutOffChange.id]).uniq.pluck('table_name')
				changesTbl.each do |tbl|
					changesKey = ChangeLogs.where(["id between ? and ? and table_name = ?",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl]).uniq.pluck(:key)
					changesKey.each do |k|
						add = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 1",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl,k])
						edit = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 2",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl,k])
						del = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 3",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl,k])

						rec = eval("#{tbl.classify}.where([\"identifier = ?\",'#{k}'])")
						if rec.length > 0
							if add.length > 0 and add.length == del.length
								# record add here and deleted (status changed, not physical remove) here...ignore the record
								logger.debug "Ignoring key #{tbl}/#{k}"
							elsif add.length > del.length 
								# record added here but not deleted
								# Ignore edit operation after that since remote node doesn't have this record anyway
								@distRec.add_new_record(rec[0])
								logger.debug "New record #{tbl}/#{k}"
							elsif del.length > add.length
								# record deleted (status changed, not physical remove) only
								@distRec.add_deleted_record(tbl,k)
								logger.debug "Deleted record #{tbl}/#{k}"
							else
								@changed = []
								edit.each do |er|
									changedFields = JSON.parse(er.changed_fields) if er.changed_fields != nil
									@changed = @changed | changedFields  # remove duplicates field name
								end
								@distRec.add_edited_record(rec[0],@changed)
								logger.debug "Edited record #{tbl}/#{k}"
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

				sl = syncHistory[0]
				sl.node_id = nodeID
				sl.last_change_log_id = cutOffChange.id
				sl.save

			else
				# no ChangeLogs record means there is no changes being made...
			end # end if cutOffChange != nil


		end

		respond_to do |format|
			#format.json { render json: YAML.dump(@distRec) }
			format.json { render json: @distRec }
		end	
	end
end
