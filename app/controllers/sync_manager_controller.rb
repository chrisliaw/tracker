class SyncManagerController < ApplicationController
  def login
		# Authenticate client node to this node
		login = params[:login]
		token = params[:token]
		begin
			cert = extract_cert(token)

		rescue Exception => ex
		end
  end

  def sync
		nodeID = params[:nodeID]
  end

	def register
		# sent the client node to this node
		cert = params[:cert]
		login = params[:login]
	end

	def node_identity
		# returns node certificate	
	end

	private
	def extract_cert(token)
		
	end
end
