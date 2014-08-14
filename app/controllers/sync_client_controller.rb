class SyncClientController < ApplicationController
  def index

  end

  def login
  end

	def sync
		host = params[:sync_client][:host]
		ops = params[:sync_client][:operation]
		node = Node.first
		url = URI.join("#{host}","sync_service/sync.json")
		Distributable::OpenWebService.call(url.to_s,:post,{"node_id" => node.identifier}) do |res|
			@result = res
		end	

		# ignore the code field...
		ignoredFields = {}
		ignoredFields[:develements] = %W(code created_at updated_at)
		ignoredFields[:projects] = %W(category_tags created_at updated_at)
		@newRecords = @result["newRec"] 
		@delRecords = @result["delRec"]
		@editRecords = @result["changedRec"]

		p @result
		@newRecords.keys.each do |type|
			obj = eval("#{type.classify}.new")
			@newRecords[type].each do |rec|
				rec.each do |k,v|
					obj.send("#{k}=",v) if ignoredFields[type.to_sym] != nil and not ignoredFields[type.to_sym].include?(k)
				end
			end

			p obj
			if obj.kind_of?(Develement) or obj.kind_of?(Issue)
				# Need project code to re-generate the code
				p = Project.where(["identifier = ?",obj.project_id])
				if p.length > 0
					obj.save
				else
					url2 = URI.join("#{host}","projects/#{obj.project_id}.json")
					Distributable::OpenWebService.call(url2.to_s,:get) do |res|
						proj = Project.new
						res.each do |k,v|
							proj.send("#{k}=",v) if not ignoredFields[:projects].include?(k)
						end	
						p proj
						proj.save
						proj.reload
						obj.project = proj
						obj.save
					end
				end
			end
		end

	end

  def download
  end

  def upload
  end
end
