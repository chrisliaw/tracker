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
		p url.to_s
		Distributable::OpenWebService.call(url.to_s,:post,{"nodeID" => node.identifier}) do |res|
			p res
		end
	end

  def download
  end

  def upload
  end
end
