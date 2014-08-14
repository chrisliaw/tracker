
#require "./lib/distributable_sync"
require 'rest-open-uri'
require 'cgi'
require 'json'
require './lib/distributed_record'
require 'yaml'

ID = "aa4bc7d0e09acded4eed2e826f0958340d65246b"

params = { "node_id" => ID }
OpenWebService = Proc.new do |url,method = :get,hash = {},&block|
	raise DistributeClientException,"No block defined for OpenWebService",caller if not block

	if hash != nil and hash.empty?
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
		#data = JSON.parse(ret)
		data = YAML.load(ret)
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

EncodeParam = Proc.new do |hash|
	encoded = []
	hash.each do |k,v|
		encoded << CGI.escape(k.to_s) + '=' + CGI.escape(v)
	end
	encoded.join '&'
end

OpenWebService.call("http://localhost:3000/projects/5442432db3457916573004514fec112ebbc42a24.json", :get) do |res|
	p res
end
