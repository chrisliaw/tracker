class SyncClientController < ApplicationController
  def index

  end

	def sync
		host = params[:sync_client][:host]
		@ops = params[:sync_client][:operation]
		node = Node.first

		if @ops == "pull"
			pull(node,host)
		else
			push(node,host)
		end # end of if-else

	end

	def push(node,host)
		# perform login
		url = URI.join("#{host}","sync_service/login.json")
		Distributable::OpenWebService.call(url.to_s,:post, {"node_id" => node.identifier}) do |res|
			@result = res
		end

		if @result["status"] == true
			@token = @result["token"]
			@server_id = @result["server_id"]

			history = SyncHistory.pending_sync_merges(@server_id)
			if history.length == 0

				@out = Distributable::GenerateDelta.call(@server_id,SyncLogs::PUSH_REF,logger)	
				logger.debug "Delta to push: #{@out.to_json}"
				url = URI.join("#{host}","sync_service/sync.json")
				Distributable::OpenWebService.call(url.to_s,:post,{"node_id" => node.identifier, "operation" => "push", "uploaded" => @out.to_json, "token" => @token }) do |res|
					@result = res
				end	

				logger.debug "Webservices push operation return #{@result}"	
				if @result["status"] == 200
					flash[:notice] = @result["status_message"]
				else
					flash[:error] = @result["status_message"]
				end

			else
				flash[:error] = %Q[It seems that you have pending merging record of #{history.length} for the target node. You have to clear the pending merging items before you can proceed to push to the target node. Click <a href="#{sync_merge_index_path(:node_id => @server_id)}">here</a> to merge the record.].html_safe
			end

		else
			# login status is false
			flash[:error] = "Failed to login to host. Error was #{@result["status_message"]}"
			render :action => "index"
		end

		redirect_to sync_client_index_path

	end

	def pull(node,host)

		# perform login
		url = URI.join("#{host}","sync_service/login.json")
		Distributable::OpenWebService.call(url.to_s,:post, {"node_id" => node.identifier}) do |res|
			@result = res
		end

		if @result["status"] == true
			@token = @result["token"]
			@server_id = @result["server_id"]

			url = URI.join("#{host}","sync_service/sync.json")
			Distributable::OpenWebService.call(url.to_s,:post,{"node_id" => node.identifier, :operation => "pull"}) do |res|
				@result = res
			end	

			#@syncSummary = Distributable::ParseDelta.call(@server_id,@token,@result,SyncLogs::PULL_REF,logger)
			# store the @result in case error happened later
			hist = SyncHistory.new
			hist.node_id = @server_id
			hist.sync_session_id = @token
			hist.sync_data = @result.to_json
			hist.status = SyncHistory::INCOMPLETE
			hist.save
			
			@syncSummary = {}
			@syncSummary[:newRecord] = {}
			@syncSummary[:delRecord] = {}
			@syncSummary[:editedRecord] = {}
			@syncSummary[:crashed] = {}

			ActiveRecord::Base.transaction do

				# ignore the code field...
				ignoredFields = {}
				ignoredFields[:default] = %W(created_at updated_id id)
				ignoredFields[:develements] = ignoredFields[:default] 
				ignoredFields[:develements] += %W(code)
				ignoredFields[:issues] = ignoredFields[:develements]
				ignoredFields[:projects] = ignoredFields[:default]
				ignoredFields[:projects] += %W(category_tags)
				ignoredFields[:dvcs_configs] = ignoredFields[:default]
				ignoredFields[:dvcs_configs] += %W(path)

				# check is there any old history which is not yet completed...
				pending = SyncHistory.where(["status = ?",SyncHistory::INCOMPLETE])
				# New record is saved before come here hence there is at least one incomplete record...
				pending.each do |pend|
					@result = JSON.parse(pend.sync_data)
					logger.debug "Processing data #{@result}"
					@newRecords = @result["newRec"] 
					@delRecords = @result["delRec"]
					@editRecords = @result["changedRec"]

					# for new record, check project first since there is the root of all linkage
					if @newRecords["projects"] != nil
						@newRecords["projects"].each do |rec|
							proj = Project.new
							rec.each do |k,v|
								proj.send("#{k}=",v) if ignoredFields[:projects] != nil and not ignoredFields[:projects].include?(k)
							end
							# check for duplicate identifier?
							dupProj = Project.where(["identifier = ?",proj.identifier])
							if dupProj.length > 0
								# DUPLICATED?????? DAMN!!
								proj.identifier = "#{proj.identifier}-d"
							end
							proj.save
						end
					end

					@newRecords.keys.each do |type|
						next if type.to_sym == :projects
						@newRecords[type].each do |rec|
							obj = eval("#{type.classify}.new")
							rec.each do |k,v|
								if ignoredFields[type.to_sym] != nil
									if not ignoredFields[type.to_sym].include?(k)
										obj.send("#{k}=",v)
									end
								else
									if not ignoredFields[:default].include?(k)
										obj.send("#{k}=",v)
									end
								end
							end

							obj.save

							@syncSummary[:newRecord][type.to_sym] = [] if @syncSummary[:newRecord][type.to_sym] == nil
							@syncSummary[:newRecord][type.to_sym] << obj.id
						end

					end

					@delRecords.each do |k,v|
						# should local delete because remote node deleted the record?? hmm...
						# If there is not changes at local, i.e. no commits, no changes, no record depending on this, can be removed...
						v.each do |id|
							begin
								obj = eval("#{k.classify}.find('#{id}')")
								@syncSummary[:delRecord][k.to_sym] = [] if @syncSummary[:delRecord][k.to_sym] == nil
								@syncSummary[:delRecord][k.to_sym] << id
							rescue ActiveRecord::RecordNotFound => ex
								# ignore
								next
							end
						end
					end

					# here will be using LOCAL_REF
					tmpRef = SyncLogs.where(["node_id = ? and direction = ?", @server_id,SyncLogs::PULL_REF])
					if tmpRef.length > 0
						@ref = tmpRef[0]
					else
						@ref = SyncLogs.new
						@ref.node_id = @server_id
						@ref.last_change_log_id = 0
						@ref.direction = SyncLogs::PULL_REF
					end

					cutOffChange = ChangeLogs.last
					if cutOffChange != nil
						@cutOffChangeID = cutOffChange.id
					else
						@cutOffChangeID = 0
					end

					if @ref.last_change_log_id == @cutOffChangeID
						logger.debug "No changed since last sync. All remote node changes merged without crash check"
						# nothing changed since last sync
						# All changes just merged with local record
						@edited = []
						@editRecords.each do |k,v|
							v.each do |rec|
								id = rec[0]
								changes = rec[1]
								changes.each do |field,value|
									obj = eval("#{k.classify}.find('#{id}')")

									if ignoredFields[k.to_sym] != nil
										if not ignoredFields[k.to_sym].include?(field)
											obj.send("#{field}=",value)
										end
									else
										if not ignoredFields[:default].include?(field)
											obj.send("#{field}=",value)
										end
									end
									#obj.send("#{field}=",value)
									obj.save
									@edited << id
								end
							end

							@syncSummary[:editedRecord][k] = {} if @syncSummary[:editedRecord][k] == nil
							@syncSummary[:editedRecord][k] = @edited
						end

					else
						logger.debug "Check for record crashing"
						# check for CRASHED changes
						@conds = []
						@conds.add_condition!(["id between ? and ?",@ref.last_change_log_id,@cutOffChangeID])

						@editRecords.each do |k,v|
							# this has the potential for changes to CRASH...
							@crashed = {}
							@edited = []
							v.each do |rec|
								id = rec[0]
								@conds.add_condition!(["table_name = ? and key = ?",k,id])
								changesSet = rec[1]
								changesSet.each do |field,value|
									cond = @conds.clone
									cond.add_condition!(["changed_fields like ? or changed_fields like ? or changed_fields like ? or changed_fields like ?","[%#{field}%]","[%,#{field},%]","[%#{field},%]","[%,#{field}]"])
									crashed = ChangeLogs.where(cond).count
									logger.debug "crashed count is #{crashed}"
									obj = eval("#{k.classify}.find('#{id}')")
									if crashed == 0
										# no crash on the field changed...merge automatically

										if ignoredFields[k.to_sym] != nil
											if not ignoredFields[k.to_sym].include?(field)
												obj.send("#{field}=",value)
											end
										else
											if not ignoredFields[:default].include?(field)
												obj.send("#{field}=",value)
											end
										end

										obj.save
										@edited << id
									else
										logger.debug "Crashed on #{id} and field #{field}"
										# CRASHED!
										curVal = obj.send("#{field}")
										if curVal != value
											@crashed[id] = [] if @crashed[id] == nil
											@crashed[id] << [field,value]
										end
									end
								end
							end

							if @edited != nil and @edited.length > 0
								@syncSummary[:editedRecord][k] = {} if @syncSummary[:editedRecord][k] == nil
								@syncSummary[:editedRecord][k] = @edited
							end

							if @crashed != nil and @crashed.length > 0
								@syncSummary[:crashed][k] = {} if @syncSummary[:crashed][k] == nil
								@syncSummary[:crashed][k] = @crashed
							end

						end

						if @syncSummary[:crashed] != nil
							@syncSummary[:crashed].each do |k,v|

								v.each do |kk,vv|
									@sm = SyncMerge.where(["sync_history_id = ? and distributable_type = ? and distributable_id = ? and status = ?",pend.id,k,kk,SyncMerge::CRASHED])
									if @sm.length == 0
										@sm = SyncMerge.new
										@sm.sync_history_id = pend.id
										@sm.distributable_type = k
										@sm.distributable_id = kk
										@sm.status = SyncMerge::CRASHED
										@sm.changeset = vv
									else
										@sm[0].changeset << vv
									end
									@sm.save
								end
							end
						end

					end

					@ref.last_change_log_id = @cutOffChangeID
					@ref.save

					pend.status = SyncHistory::COMPLETED
					pend.save

				end
			end # end transaction

			if @syncSummary[:crashed] != nil and @syncSummary[:crashed].size > 0
				flash[:notice] = %Q[There are conflicted record for the pull operation. Please click <a href="#{sync_merge_index_path(:node_id => @server_id)}">here</a> to resolve the conflict].html_safe
			else
				flash[:notice] = %Q[The data pull operation succeeded]
			end

			#redirect_to sync_client_index_path
		else
			# login status is false
			flash[:error] = "Failed to login to host. Error was #{@result["status_message"]}"
			#render :action => "index"
		end

		redirect_to sync_client_index_path
  end
end
