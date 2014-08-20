class SyncMergeController < ApplicationController
  def index
		@nodeID = params[:node_id]
		if @nodeID != nil
			@conflicted = []
			hist = SyncHistory.where(["node_id = ?",@nodeID])
			hist.each do |his|
				his.sync_merges.each do |sm|
					@conflicted << sm if sm.status == SyncMerge::CRASHED
				end
			end
			@conflicted
		else
			@conflicted = SyncMerge.where(["status = ?",SyncMerge::CRASHED])
		end
  end

  def show
		@rec = SyncMerge.find params[:id]
		@nodeID = params[:node_id]
  end

  def update
		@data = SyncMerge.find params[:sm_id]
		commit = params[:commit]

		@target = eval("#{@data.distributable_type.classify}.find('#{@data.distributable_id}')")
		chg = YAML.load(@data.changeset)
		chg.each do |c|
			if commit == "Accept Local"
				@target.send("#{c[0]}=",params[@data.distributable_type.to_sym][c[0]])
			else
				@target.send("#{c[0]}=",params[@data.distributable_type.to_sym]["new_#{c[0]}"])
			end
		end

		if @target.save
			@data.status = SyncMerge::MERGED
			@data.save
		else
			flash[:error] = "Error merging data. Error was #{@target.errors}"
		end
		
		redirect_to :action => "index"
  end
end
