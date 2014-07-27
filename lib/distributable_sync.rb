
class DistributeClientException < Exception; end
module Distributable
	LoginNode = Proc.new do 
		# load the node id
		# sign the constant with node id
		# sent node id to remote node
	end

	RegisterNode = Proc.new do
		# load the node id
		# sent the local node id to remote node for registration
	end

	SyncNode = Proc.new do |token|
		# after got the login token
		# perform pull first to allow remote node new changes download to this node
		# perform integration of downloaded data with local data
		# perform push the changed data from local store to remote node
	end

	PullData = Proc.new do |host,token|

	end

	PushRecord = Proc.new do |host,token|

	end

	MergeRecord = Proc.new do |rec|

	end

	OpenWebService = Proc.new do |url,method,hash,&block|
		raise DistributeClientException,"No block defined for OpenWebService",caller if not block

		if hash.empty?
			res = open(url,:method => method)
		else
			res = open(url,:method => method, :body => EncodeParam.call(hash))
		end
		# read all content from StringIO first
		ret = []
		res.each_line do |l|
			ret << l
		end
		ret = ret.join("\n")
		if ret.length > 0 and ret != "null"
			data = JSON.parse(ret)
			if data.is_a? Array
				data.each do |d|
					block.call(d)
				end
			else
				block.call(data)
			end
		else
			block.call("")
		end
	end
end
