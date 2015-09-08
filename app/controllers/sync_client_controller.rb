class SyncClientController < ApplicationController
  def index

  end

	def sync
		@host = params[:sync_client][:host]
		@ops = params[:sync_client][:operation]
		node = Node.first

		if @ops == "pull"
			pull(node,@host,session[:user][:pass])
		else
			push(node,@host,session[:user][:pass])
		end # end of if-else

	end

	def push(node,host,pass)
		# perform login
		@result = node_login(host,node,pass)
		#url = URI.join("#{host}","sync_service/login.json")
		#Distributable::OpenWebService.call(url.to_s,:post, {"node_id" => node.identifier}) do |res|
		#	@result = res
		#end

		if @result["status"] == 200
			@token = @result["token"]
			@server_id = @result["server_id"]

			status,tok,serverID,newNode = generate_server_token(@token,@server_id)
			if status
				@token = tok
				@server_id = serverID
				history = SyncHistory.pending_sync_merges(@server_id)
				if history.length == 0

					@out,@sl = Distributable::GenerateDelta.call(@server_id,SyncLogs::PUSH_REF,logger)	
					logger.debug "Delta to push: #{@out.to_json}"
					url = URI.join("#{host}","sync_service/sync.json")
					Distributable::OpenWebService.call(url.to_s,:post,{"node_id" => node.identifier, "operation" => "push", "uploaded" => @out.to_json, "token" => @token }) do |res|
						@result = res
					end	

					logger.debug "Webservices push operation return #{@result}"	
					if @result["status"] == 200
						flash[:notice] = @result["status_message"]
						# make the sync log changes permanent
						@sl.save if @sl != nil
					else
						flash[:error] = @result["status_message"]
					end

				else
					flash[:error] = %Q[It seems that you have pending merging record of #{history.length} for the target node. You have to clear the pending merging items before you can proceed to push to the target node. Click <a href="#{sync_merge_index_path(:node_id => @server_id)}">here</a> to merge the record.].html_safe
				end

			else
				# server token processing failed
				flash[:error] = tok
			end
		else
			# login status is false
			flash[:error] = "Failed to login to host. Error was #{@result["status_message"]}"
			render :action => "index"
		end

		#redirect_to sync_client_index_path

	end

	def pull(node,host,pass)

		@result = node_login(host,node,pass)
		# perform login
		#url = URI.join("#{host}","sync_service/login.json")
		#Distributable::OpenWebService.call(url.to_s,:post, {"node_id" => node.identifier}) do |res|
		#	@result = res
		#end
					@syncSummary = {}
					@syncSummary[:newRecord] = {}
					@syncSummary[:delRecord] = {}
					@syncSummary[:editedRecord] = {}
					@syncSummary[:crashed] = {}
					@syncSummary[:incons] = {} # inconsistant record

		if @result["status"] == 200
			@token = @result["token"]
			@server_id = @result["server_id"]

			status,tok,serverID,newNode = generate_server_token(@token,@server_id)
			if status
				@token = tok
				@server_id = serverID
				# server token processing successful..proceed to operation
				url = URI.join("#{host}","sync_service/sync.json")
				Distributable::OpenWebService.call(url.to_s,:post,{"token" => tok, "node_id" => node.identifier, :operation => "pull"}) do |res|
					@result = res
				end	

				logger.debug "Pull result is #{@result}"
				if @result["status"] == 200
					# store the @result in case error happened later
					hist = SyncHistory.new
					hist.node_id = @server_id
					hist.sync_session_id = @token
					hist.sync_data = @result["status_message"].to_json
					hist.status = SyncHistory::INCOMPLETE
					hist.host = host
					hist.direction = SyncLogs::PULL_REF
					hist.save

					log = Logger.new File.join(Rails.root,"log","sync_pull.log"), 'daily'

					ActiveRecord::Base.transaction do

						# These are the master tables which needs to be created the data first before 
						# subsequent data can be created due to field linkages
						master = [:projects, :schedules, :variances, :version_controls, :packages]
						# Start transaction for master record only
						#ActiveRecord::Base.transaction do

							# ignore the code field...
							ignoredFields = {}
							ignoredFields[:default] = %W(created_at updated_id id)
							master.each do |ma|
								ignoredFields[ma] = ignoredFields[:default]
							end
							#ignoredFields[:projects] = ignoredFields[:default]
							ignoredFields[:projects] += %W(category_tags)
							#ignoredFields[:schedules] = ignoredFields[:default]

							# check is there any old history which is not yet completed...
							pending = SyncHistory.where(["status = ?",SyncHistory::INCOMPLETE])
							# New record is saved before come here hence there is at least one incomplete record...
							pending.each do |pend|
								@result = JSON.parse(pend.sync_data)
								logger.debug "Processing new data for master first #{@result}"
								@newRecords = @result["newRec"] 

								master.each do |mas|
									if @newRecords[mas.to_s] != nil
										@newRecords[mas.to_s].each do |rec|

											obj = eval("#{mas.to_s.classify}.new")
											rec.each do |k,v|
												if ignoredFields[mas.to_s] != nil
													if not ignoredFields[mas.to_s].include?(k)
														obj.send("#{k}=",v)
													end
												else
													if not ignoredFields[:default].include?(k)
														obj.send("#{k}=",v)
													end
												end
											end

											st = obj.save

											log.debug "#{mas.to_s} / #{obj.identifier} created as new"
											shd = SyncHistoryDetail.new
											shd.table_name = mas.to_s
											shd.identifier = obj.identifier
											shd.operation = SyncHistoryDetail::NEW_RECORD
											shd.status = st
											hist.sync_history_details << shd

											@syncSummary[:newRecord][mas] = [] if @syncSummary[:newRecord][mas] == nil
											@syncSummary[:newRecord][mas] << obj.id

										end  # end 
									end

								end # end looping master tables

								# continue other new record
								@newRecords.keys.each do |type|
									next if master.include?(type.to_sym) # == :projects or type.to_sym == :schedules
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

										res = obj.save
											shd = SyncHistoryDetail.new
											shd.table_name = type
											shd.identifier = obj.identifier
											shd.operation = SyncHistoryDetail::NEW_RECORD
											shd.status = res
											hist.sync_history_details << shd

										log.debug "#{type} / #{obj.identifier} created as new (#{res})"

										@syncSummary[:newRecord][type.to_sym] = [] if @syncSummary[:newRecord][type.to_sym] == nil
										@syncSummary[:newRecord][type.to_sym] << obj.id
									end
								end
								# done looping new record from remote node


								## for new record, check project first since there is the root of all linkage...
								## Project has to commit first due to later there are references needs valid project data in database
								#if @newRecords["projects"] != nil
								#	@newRecords["projects"].each do |rec|
								#		puts "New project from upstream #{rec}"
								#		proj = Project.new
								#		rec.each do |k,v|
								#			proj.send("#{k}=",v) if ignoredFields[:projects] != nil and not ignoredFields[:projects].include?(k)
								#		end
								#		# check for duplicate identifier?
								#		dupProj = Project.where(["identifier = ?",proj.identifier])
								#		if dupProj.length > 0
								#			# DUPLICATED?????? DAMN!!
								#			logger.warn "Duplicated project identifier? #{proj.identifier}"
								#			#proj.identifier = "#{proj.identifier}-d"
								#		else
								#			proj.save

								#			@syncSummary[:newRecord][:projects] = [] if @syncSummary[:newRecord][:projects] == nil
								#			@syncSummary[:newRecord][:projects] << proj.id
								#		end  # end duplicate project check
								#	end  # end new record on project looping
								#end
								## done looping new project from remote node
								#
								## for new record, check schedule second since there is the develement/issues might bind to schedule as well
								## Schedule has to commit next due to later there are references needs valid schedule data in database
								#if @newRecords["schedules"] != nil
								#	@newRecords["schedules"].each do |rec|
								#		puts "New schedule from upstream #{rec}"
								#		schedule = Schedule.new
								#		rec.each do |k,v|
								#			schedule.send("#{k}=",v) if ignoredFields[:schedules] != nil and not ignoredFields[:schedules].include?(k)
								#		end
								#		# check for duplicate identifier?
								#		dupSche = Schedule.where(["identifier = ?",schedule.identifier])
								#		if dupSche.length > 0
								#			# DUPLICATED?????? DAMN!!
								#			logger.warn "Duplicated schedule identifier? #{schedule.identifier}"
								#			# this is wrong! all child data link to crashed identifier
								#			#proj.identifier = "#{schedule.identifier}-d"
								#		else
								#			schedule.save

								#			@syncSummary[:newRecord][:schedules] = [] if @syncSummary[:newRecord][:schedules] == nil
								#			@syncSummary[:newRecord][:schedules] << schedule.id
								#		end  # end if duplicate check
								#	end # end new schedule data set


								#end
								## done looping new project from remote node

							end # end looping sync history record

						#end # end transaction for new project



						# ignore the code field...
						ignoredFields = {}
						ignoredFields[:default] = %W(created_at updated_id id)
						ignoredFields[:develements] = ignoredFields[:default] 
						ignoredFields[:develements] += %W(code)
						ignoredFields[:issues] = ignoredFields[:default]
						ignoredFields[:issues] += %W(code)
						#ignoredFields[:projects] = ignoredFields[:default]
						#ignoredFields[:projects] += %W(category_tags)
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
							#if @newRecords["projects"] != nil
							#	@newRecords["projects"].each do |rec|
							#		proj = Project.new
							#		rec.each do |k,v|
							#			proj.send("#{k}=",v) if ignoredFields[:projects] != nil and not ignoredFields[:projects].include?(k)
							#		end
							#		# check for duplicate identifier?
							#		dupProj = Project.where(["identifier = ?",proj.identifier])
							#		if dupProj.length > 0
							#			# DUPLICATED?????? DAMN!!
							#			logger.warn "Duplicated project identifier? #{proj.identifier}"
							#			proj.identifier = "#{proj.identifier}-d"
							#		end
							#		proj.save
							#	end
							#end
							# done looping new project from remote node

							## continue other new record
							#@newRecords.keys.each do |type|
							#	next if master.include?(type.to_sym) # == :projects or type.to_sym == :schedules
							#	@newRecords[type].each do |rec|
							#		obj = eval("#{type.classify}.new")
							#		rec.each do |k,v|
							#			if ignoredFields[type.to_sym] != nil
							#				if not ignoredFields[type.to_sym].include?(k)
							#					obj.send("#{k}=",v)
							#				end
							#			else
							#				if not ignoredFields[:default].include?(k)
							#					obj.send("#{k}=",v)
							#				end
							#			end
							#		end

							#		obj.save

							#		log.debug "#{type} / #{obj.identifier} created as new"

							#		@syncSummary[:newRecord][type.to_sym] = [] if @syncSummary[:newRecord][type.to_sym] == nil
							#		@syncSummary[:newRecord][type.to_sym] << obj.id
							#	end
							#end
							## done looping new record from remote node

							# Now analyze deleted record...
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

									log.debug "#{k} / #{v} is considered deleted record"
											shd = SyncHistoryDetail.new
											shd.table_name = k
											shd.identifier = id
											shd.operation = SyncHistoryDetail::DEL_RECORD
											hist.sync_history_details << shd
								end
							end
							# done deleted record processing

							# Now processing edited record...
							# First get the last change log record for this remote node
							tmpRef = SyncLogs.where(["node_id = ? and direction = ?", @server_id,SyncLogs::PULL_REF])
							if tmpRef.length > 0
								@ref = tmpRef[0]
							else
								@ref = SyncLogs.new
								@ref.node_id = @server_id
								@ref.last_change_log_id = 0
								@ref.direction = SyncLogs::PULL_REF
							end

							# Lock down the change log pointer so that it is ok if there is other transaction going on while updating is done
							cutOffChange = ChangeLogs.last
							if cutOffChange != nil
								@cutOffChangeID = cutOffChange.id
							else
								@cutOffChangeID = 0
							end

							# Node has not changed since last sync...remote node changes are not checked for conflicted changes
							if @ref.last_change_log_id == @cutOffChangeID
								logger.debug "No changed since last sync. All remote node changes merged without crash check"
								# nothing changed since last sync
								# All changes just merged with local record
								@edited = []
								@editRecords.each do |k,v|
									v.each do |rec|
										id = rec[0]
										obj = eval("#{k.classify}.find('#{id}')")

										changes = rec[1]
										changes.each do |field,value|

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
											#obj.save
											#@edited << id
										end # done setting all the changed value

											res = obj.save
											@edited << id
										log.debug "#{k.classify} / #{obj.identifier} is edited record with no crashing"
											shd = SyncHistoryDetail.new
											shd.table_name = k
											shd.identifier = obj.identifier
											shd.operation = SyncHistoryDetail::UPDATE_RECORD
											shd.status = res
											hist.sync_history_details << shd
									end

									@syncSummary[:editedRecord][k] = {} if @syncSummary[:editedRecord][k] == nil
									@syncSummary[:editedRecord][k] = @edited
								end

							else 
								# If last processed change log is not the same as current change log id
								# This node has already has some changes...so conflicted changes check is done
								logger.debug "Check for record crashing"
								# check for CRASHED/CONFLICTED changes
								@conds = []
								@conds.add_condition!(["id between ? and ?",@ref.last_change_log_id,@cutOffChangeID])

								@editRecords.each do |k,v|
									# this has the potential for changes to CRASH...
									@crashed = {}
									@edited = []
									v.each do |rec|
										id = rec[0]
										#obj = eval("#{k.classify}.find('#{id}')")
										# Change from find to where is to prevent error if the edited record is new record
										# which not yet exist at local yet...Those record only shows up AFTER the transaction
										obj = eval("#{k.classify}.where(\"identifier = '#{id}'\")")
										logger.debug "Selected obj is #{obj.inspect}"
										#@conds.add_condition!(["table_name = ? and key = ?",k,id])
										changesSet = rec[1]
										changesSet.each do |field,value|
											cond = @conds.clone
											cond.add_condition!(["table_name = ? and key = ?",k,id])
											cond.add_condition!(["changed_fields like ? or changed_fields like ? or changed_fields like ? or changed_fields like ?","[%#{field}%]","[%,#{field},%]","[%#{field},%]","[%,#{field}]"])
											crashed = ChangeLogs.where(cond).count
											logger.debug "crashed count is #{crashed}"
											# what if an record marked as changed but not in local database?
											# This seems like data inconsistancy...Should back patch or ignore?
											# Back patch:
											# Pro : Fix data issue for user
											# Cons : Might complicate handling of processing
											#
											# Ignore:
											# Pro : Failed silently
											# Cons : Record not being copied over. Data not consistant
											#
											# However if copied over, the project code might crashed as well!
											#obj = eval("#{k.classify}.find('#{id}')")
											# Change from find to where is to prevent error if the edited record is new record
											# which not yet exist at local yet...Those record only shows up AFTER the transaction
											#obj = eval("#{k.classify}.where(\"identifier = '#{id}'\")")
											# if the record already exist!
											if obj.length > 0
												objj = obj[0]
												if crashed == 0
													# no crash on the field changed...merge automatically
													if ignoredFields[k.to_sym] != nil
														if not ignoredFields[k.to_sym].include?(field)
															objj.send("#{field}=",value)
														end
													else
														if not ignoredFields[:default].include?(field)
															objj.send("#{field}=",value)
														end
													end

													res = objj.save
													@edited << id

													log.debug "#{k.classify} / #{objj.identifier} is edited record with no crashing"
													shd = SyncHistoryDetail.new
													shd.table_name = k
													shd.identifier = objj.identifier
													shd.operation = SyncHistoryDetail::UPDATE_RECORD
													shd.status = res
													shd.crash_flag = SyncHistoryDetail::NO_CRASH
													hist.sync_history_details << shd
												else
													realCrash = false
													if ignoredFields[k.to_sym] != nil
														if not ignoredFields[k.to_sym].include?(field)
															# CRASHED!
															logger.debug "Crashed on #{id} and field #{field}"
															curVal = objj.send("#{field}")
															if curVal != value
																@crashed[id] = [] if @crashed[id] == nil
																@crashed[id] << [field,value]
																realCrash = true
															end
															#obj.send("#{field}=",value)
														end
													else
														if not ignoredFields[:default].include?(field)
															# CRASHED!
															logger.debug "Crashed on #{id} and field #{field}"
															curVal = objj.send("#{field}")
															if curVal != value
																@crashed[id] = [] if @crashed[id] == nil
																@crashed[id] << [field,value]
																realCrash = true
															end

															#obj.send("#{field}=",value)
														end
													end

													if realCrash
														log.debug "#{k.classify} / #{objj.identifier} is edited record with crashed fields #{field}"
														shd = SyncHistoryDetail.new
														shd.table_name = k
														shd.identifier = objj.identifier
														shd.operation = SyncHistoryDetail::UPDATE_RECORD
														shd.crash_flag = SyncHistoryDetail::CRASHED
														hist.sync_history_details << shd
													end
													# CRASHED!
													#logger.debug "Crashed on #{id} and field #{field}"
													#curVal = obj.send("#{field}")
													#if curVal != value
													#	@crashed[id] = [] if @crashed[id] == nil
													#	@crashed[id] << [field,value]
													#end
												end # end if crashed == 0

											else
												# Record with this identifier not found locally
												# Remote node indicated the operation done on that remote node
												# is edit operation.
												# If it is generated on that remote node, it would have been 
												# capture by the above logic to create new record.
												# Now remote node saying it was edited but not exist locally...hmm...
												# One conditions of this found during dev is that the remote node
												# has no change_log function implement yet. Record was created without
												# logging into change_log database. It was only registered as edit
												# after change_log function is activated
												# Current handling : Ignored and no future action will be done
												# Most likely this only happen during development stage.
												log.debug "#{k.classify} / #{id} is ignored edited record"
													shd = SyncHistoryDetail.new
													shd.table_name = k
													shd.identifier = id
													shd.operation = SyncHistoryDetail::UPDATE_RECORD
													shd.crash_flag = SyncHistoryDetail::IGNORED
													hist.sync_history_details << shd
											end  # end if obj.length > 0

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

								# save the crashed/conflicted changes inside the table for manual merging purposes
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
								# done save the conflicted record
							end # done looping all the changes

							# marked the last change log id reference in table
							@ref.last_change_log_id = @cutOffChangeID
							@ref.save

							# mark the history is done
							pend.status = SyncHistory::COMPLETED
							pend.save
						end # end looping sync history record

					end # end transaction

					# Save the history details
					hist.save
					@history = hist

					if @syncSummary[:crashed] != nil and @syncSummary[:crashed].size > 0
						flash[:notice] = %Q[There are conflicted record for the pull operation. Please click <a href="#{sync_merge_index_path(:node_id => @server_id)}">here</a> to resolve the conflict].html_safe
					else
						flash[:notice] = %Q[The data pull operation succeeded]
					end

				else
					# sync controller return error codes
					flash[:error] = "Failed to execute sync operation on remote node. Error message was : #{@result["status_message"]}"
				end

			else
				# server token processing failed
				flash[:error] = tok
			end

		else
			# login status is false
			flash[:error] = "Failed to login to host. Error was #{@result["status_message"]}"
			#render :action => "index"
		end

		#redirect_to sync_client_index_path
	end

	private
	def node_login(host,node,pass)
		idUrl = File.join(Rails.root,"db","owner.id")
		@result = {}
		begin
			pkey,cert,chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,pass)
			signed = AnCAL::DataSign::PKCS7::SignData.call(pkey,cert,node.identifier,false)
			
			url = URI.join("#{host}","sync_service/login.json")
			Distributable::OpenWebService.call(url.to_s,:post, {"node_id" => signed.to_pem}) do |res|
				@result = res
			end
		rescue Exception => ex
			@result["status"] = false
			@result["status_message"] = "Failed to activate the node ID. Error message was #{ex}"
		end

		@result
	end

	def generate_server_token(encToken,signedID)
		#p encToken
		#p signedID
		# Load local node key
		idUrl = File.join(Rails.root,"db","owner.id")
		pkey,cert,chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,session[:user][:pass])

		# Decrypt session key generated by server side
		token = AnCAL::Cipher::PKCS7::DecryptData.call(pkey,cert,encToken.hex_to_bin)
		# Verify signature generated by remote node
		detached,certs,signers = AnCAL::DataSign::PKCS7::ParseSignedData.call(signedID)
		if certs.length > 0
			# TODO verify remote node certificate
			# Verify signature by using the remote node certificate as input data
			status,p7 = AnCAL::DataSign::PKCS7::VerifyData.call(certs[0],signedID) do |ok,ctx|
				if ctx.current_cert != nil
					true
				else
					false
				end
			end

			if status
				# Store the node token to allow user validation later. Pretty much like SSH host key validation
				@newHost = nil
				u = User.where(["cert = ?",certs[0].to_pem])
				if u.length == 0
					u = User.new
					u.login = certs[0].subject.to_s
					u.cert = certs[0].to_pem
					u.validation_token = signedID
					u.state = "pending"
					u.rights = ""
					u.groups = User::REMOTE_HOST_GROUP
					u.save
					@newHost = u
				else
					u[0].validation_token = signedID
					u[0].save
				end
				# generate token
				# Basically pass back the session key given by remote node to prove that we 
				# have the private key to decrypt the data and proves our identity
				tok = AnCAL::Cipher::PKCS7::EncryptData.call(certs[0],token)
				[true,tok.to_hex,p7.data,@newHost]
			else
				[false,"Failed to verify target node token. Authentic token info not available."]
			end
		else
			# target node cert not avail in the signature!
			[false,"Target node did not provide any valid token to further processing"]
		end
	end
end
