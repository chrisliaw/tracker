class SyncMergeController < ApplicationController
  def index
		@conflicted = SyncMerge.where(["status = ?",SyncMerge::CRASHED])
  end

  def show
		@rec = SyncMerge.find params[:id]
  end

  def update
		@data = SyncMerge.find params[:sm_id]
		@target = eval("#{@data.distributable_type.classify}.find('#{@data.distributable_id}')")
		chg = YAML.load(@data.changeset)
		chg.each do |c|
			@target.send("#{c[0]}=",params[:project][c[0]])
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
