class SyncServiceController < ApplicationController
	skip_before_filter :verify_authenticity_token, :only => [:login]	
  def login
		clientNodeID = params[:node_id]
		node = Node.first
		Struct.new("LoginStatus",:status, :status_message, :token, :server_id)

		detached,certs,signers = AnCAL::DataSign::PKCS7::ParseSignedData.call(clientNodeID)
		if certs.length > 0
			# find this cert in our user table?
			user = User.where(["cert = ?",certs[0].to_pem])
			if user.length > 0
				if user[0].state == "active"
					status,p7 = AnCAL::DataSign::PKCS7::VerifyData.call(certs[0],clientNodeID) do |ok,ctx|
						if ctx.current_cert != nil and ctx.current_cert.to_pem == user[0].cert
							true
						else
							false
						end
					end

					if status
						aNode = Node.where(["identifier = ?",p7.data])
						if aNode.length > 0
							if aNode[0].state != "active"
								retData = Struct::LoginStatus.new(500,"Node is not in active state","","")
							else
								nodeSess = SecureRandom.uuid
								user[0].validation_token = nodeSess
								user[0].save

								# encrypt the session id
								encSess = AnCAL::Cipher::PKCS7::EncryptData.call(certs[0],nodeSess)
								# sign the node id
								idUrl = File.join(Rails.root,"db","owner.id")
								begin
									pass = load_cache_password(node.identifier)
									pkey,cert,chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,pass)
									signed = AnCAL::DataSign::PKCS7::SignData.call(pkey,cert,node.identifier,false)
									retData = Struct::LoginStatus.new(200,"User authenticated",encSess.to_hex,signed.to_pem)
								rescue Exception => ex
									p ex
									retData = Struct::LoginStatus.new(500,ex.message,"","")
								end

							end
						else
							node = Node.new
							node.identifier = p7.data
							node.rights = "NoAccess"
							node.submitted_by = certs[0].to_pem
							node.save
							retData = Struct::LoginStatus.new(401,"Node is not authorized","","")
						end
					else
						# data signature verification failed
						retData = Struct::LoginStatus.new(401,"Client token verification failed. Login failed.","","")
					end

				else
					# user state is not active
					retData = Struct::LoginStatus.new(401,"User is not in active state. Currently it is #{user[0].state}.","","")
				end
			else
				# user not found in database...
				# save it...
				u = User.new
				u.login = certs[0].subject.to_s
				u.cert = certs[0].to_pem
				u.validation_token = clientNodeID	
				u.state = "pending"
				u.rights = ""
				u.groups = User::REMOTE_USER_GROUP
				u.save
				retData = Struct::LoginStatus.new(201,"User is not in list. Request has been created and upon authorized by administrator, you can retry again.","","")
			end
		else
			# no cert available in the incoming data
			retData = Struct::LoginStatus.new(400,"Request no given appropriate data for authentication","","")
		end
		#Struct.new("LoginStatus",:status, :status_message, :token, :server_id)
		#retData = Struct::LoginStatus.new(true,"Authenticated",nodeSess,node.identifier)
		respond_to do |format|
			format.json { render json: retData }
		end
  end

  def index
		@users = User.where(["groups = ?",User::REMOTE_USER_GROUP])

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @users }
		end
	end

	def sync
		ops = params[:operation]
		nodeID = params[:node_id]		
		token = params[:token]
		uploaded = params[:uploaded]
		Struct.new("SyncStatus",:status, :status_message)

		if validate_token(token)
			aNode = Node.where(["identifier = ?",nodeID])
			if ops == "pull"
				if aNode[0].rights != nil and not aNode[0].rights.empty? and (aNode[0].rights =~ /Pull/) != nil
					out = Distributable::GenerateDelta.call(nodeID,SyncLogs::PULL_REF,logger)
					@out = Struct::SyncStatus.new(200,out)
					#@out = pull(nodeID)
				else
					@out = Struct::SyncStatus.new(401,"Your node is not allow to pull from this host")
				end
			else
				if aNode[0].rights != nil and not aNode[0].rights.empty? and (aNode[0].rights =~ /Push/) != nil
					out = handle_push(nodeID,token,uploaded)
					@out = Struct::SyncStatus.new(200,out)
				else
					@out = Struct::SyncStatus.new(401,"Your node is not allow to push to this host")
				end
			end
		else
			@out = Struct::SyncStatus.new(401,"Session ID invalid. Please login before call sync operation")
		end

		p @out
		respond_to do |format|
			#format.json { render json: YAML.dump(@distRec) }
			format.json { render json: @out }
		end	
	end

	private
  def handle_push(nodeID,token,uploaded)
		# TODO : Can this node and user id push?
		@syncHistory = SyncLogs.where(["node_id = ? and direction = ?",nodeID,SyncLogs::PULL_REF])
		cutOffChange = ChangeLogs.last
		if @syncHistory.length > 0 and cutOffChange.id == @syncHistory[0].last_change_log_id # this show the client node is in sync with my node

			# store the result in case error happened later
			hist = SyncHistory.new
			hist.node_id = nodeID
			hist.sync_session_id = token
			hist.sync_data = uploaded
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
					logger.debug @result
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

					pend.status = SyncHistory::COMPLETED
					pend.save

				end
			end # end transaction

			@syncHistory[0].last_change_log_id = cutOffChange.id
			@syncHistory[0].save
			{:status => 200, :status_message => "Data integrated successfully"}
		else
			# the client never pull from me before!
			# ask client to go away
			if @syncHistory.length == 0
				{ :status => 501, :status_message => "Please perform pull before try to push to this server"}
			elsif @syncHistory.length > 0 and @syncHistory[0].last_change_log_id != cutOffChange.id
				{ :status => 502, :status_message => "Server has #{cutOffChange.id-@syncHistory[0].last_change_log_id} changes since your last pull. Please pull again before push"}
			else
				{ :status => 500, :status_message => "Other error"}
			end
		end

  end

  #def pull(nodeID)
	#	syncHistory = SyncLogs.where(["node_id = ? and direction = ?",nodeID,SyncLogs::PULL_REF])
	#	@distRec = Distributable::DistributableRecord.new
	#	# operation: 1 - add, 2 - edit, 3 - delete
	#	# Note the sync does not push history to another node. History is always local. Only data will be pushed to another node
	#	if syncHistory.length == 0
	#		# never come here before
	#		cutOffChange = ChangeLogs.last
	#		if cutOffChange != nil
	#			changesTbl = ChangeLogs.where(["id between ? and ?",0,cutOffChange.id]).uniq.pluck('table_name')
	#			changesTbl.each do |tbl|
	#				changesKey = ChangeLogs.where(["id between ? and ? and table_name = ?",0,cutOffChange.id,tbl]).uniq.pluck(:key)
	#				changesKey.each do |k|
	#					add = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 1",0,cutOffChange.id,tbl,k])
	#					edit = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 2",0,cutOffChange.id,tbl,k])
	#					del = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 3",0,cutOffChange.id,tbl,k])

	#					rec = eval("#{tbl.classify}.where([\"identifier = ?\",'#{k}'])")
	#					if rec.length > 0
	#						if add.length > 0 and add.length == del.length
	#							# record add here and deleted (status changed, not physical remove) here...ignore the record
	#						elsif add.length > del.length 
	#							# record added here but not deleted
	#							# Ignore edit operation after that since remote node doesn't have this record anyway
	#							@distRec.add_new_record(rec[0])
	#						elsif del.length > add.length
	#							# record deleted (status changed, not physical remove) only
	#							@distRec.add_deleted_record(tbl,k)
	#						else
	#							@changed = []
	#							edit.each do |er|
	#								changedFields = JSON.parse(er.changed_fields) if er.changed_fields != nil
	#								@changed = @changed | changedFields  # remove duplicates field name
	#							end
	#							@distRec.add_edited_record(rec[0],@changed)
	#						end
	#					else
	#						# deleted record from database will fall under here
	#						logger.warn("Can not find record from table #{tbl} with id #{k} to sync. Probably deleted?")
	#						if add.length == del.length
	#							# record add here and deleted (status changed, not physical remove) here...ignore the record
	#						elsif del.length > add.length
	#							@distRec.add_deleted_record(tbl,k)
	#						end
	#					end
	#				end

	#			end # end changed table loop

	#			sl = SyncLogs.new
	#			sl.node_id = nodeID
	#			sl.last_change_log_id = cutOffChange.id
	#			sl.direction = SyncLogs::PULL_REF
	#			sl.save

	#		else
	#			# no ChangeLogs record means there is no changes being made...
	#		end # end if cutOffChange != nil

	#	else
	#		# this node came here before...
	#		cutOffChange = ChangeLogs.last
	#		if cutOffChange != nil and syncHistory[0].last_change_log_id != cutOffChange.id
	#			changesTbl = ChangeLogs.where(["id between ? and ?",syncHistory[0].last_change_log_id+1,cutOffChange.id]).uniq.pluck('table_name')
	#			changesTbl.each do |tbl|
	#				changesKey = ChangeLogs.where(["id between ? and ? and table_name = ?",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl]).uniq.pluck(:key)
	#				changesKey.each do |k|
	#					add = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 1",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl,k])
	#					edit = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 2",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl,k])
	#					del = ChangeLogs.where(["id between ? and ? and table_name = ? and key = ? and operation = 3",syncHistory[0].last_change_log_id+1,cutOffChange.id,tbl,k])

	#					rec = eval("#{tbl.classify}.where([\"identifier = ?\",'#{k}'])")
	#					if rec.length > 0
	#						if add.length > 0 and add.length == del.length
	#							# record add here and deleted (status changed, not physical remove) here...ignore the record
	#							logger.debug "Ignoring key #{tbl}/#{k}"
	#						elsif add.length > del.length 
	#							# record added here but not deleted
	#							# Ignore edit operation after that since remote node doesn't have this record anyway
	#							@distRec.add_new_record(rec[0])
	#							logger.debug "New record #{tbl}/#{k}"
	#						elsif del.length > add.length
	#							# record deleted (status changed, not physical remove) only
	#							@distRec.add_deleted_record(tbl,k)
	#							logger.debug "Deleted record #{tbl}/#{k}"
	#						else
	#							@changed = []
	#							edit.each do |er|
	#								changedFields = JSON.parse(er.changed_fields) if er.changed_fields != nil
	#								@changed = @changed | changedFields  # remove duplicates field name
	#							end
	#							@distRec.add_edited_record(rec[0],@changed)
	#							logger.debug "Edited record #{tbl}/#{k}"
	#						end
	#					else
	#						# deleted record from database will fall under here
	#						logger.warn("Can not find record from table #{tbl} with id #{k} to sync. Probably deleted?")
	#						if add.length == del.length
	#							# record add here and deleted (status changed, not physical remove) here...ignore the record
	#						elsif del.length > add.length
	#							@distRec.add_deleted_record(tbl,k)
	#						end
	#					end
	#				end

	#			end # end changed table loop

	#			sl = syncHistory[0]
	#			sl.node_id = nodeID
	#			sl.last_change_log_id = cutOffChange.id
	#			sl.direction = SyncLogs::PULL_REF
	#			sl.save

	#		else
	#			# no ChangeLogs record means there is no changes being made...
	#		end # end if cutOffChange != nil


	#	end


	#	@distRec
  #end

	def validate_token(token)
		node = Node.first
		idUrl = File.join(Rails.root,"db","owner.id")
		begin
			pass = load_cache_password(node.identifier)
			pkey,cert,chain = AnCAL::KeyFactory::FromP12Url.call(idUrl,pass)
			nodeSess = AnCAL::Cipher::PKCS7::DecryptData.call(pkey,cert,token.hex_to_bin)
			u = User.where(["validation_token = ?",nodeSess])
			if u.length == 0
				false
			else
				true
			end
		rescue Exception => ex
			p ex
			false
		end
	end
end
