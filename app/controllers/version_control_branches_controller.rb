class VersionControlBranchesController < ApplicationController

	before_filter :find_parent
	def find_parent
		@version_control = VersionControl.find params[:version_control_id]
		@project = @version_control.versionable if @version_control != nil
	end
  # GET /version_control_branches
  # GET /version_control_branches.json
  def index
    @version_control_branches = VersionControlBranch.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @version_control_branches }
    end
  end

  # GET /version_control_branches/1
  # GET /version_control_branches/1.json
  def show
    @version_control_branch = VersionControlBranch.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @version_control_branch }
    end
  end

  # GET /version_control_branches/new
  # GET /version_control_branches/new.json
  def new
    @version_control_branch = VersionControlBranch.new
		@schedule_states = []
		Schedule.states.each do |sst|
			@schedule_states << sst.to_s
		end
		@schedule_states = @schedule_states - @version_control.already_defined_schedule_states
    
		respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @version_control_branch }
    end
  end

  # GET /version_control_branches/1/edit
  def edit
    @version_control_branch = VersionControlBranch.find(params[:id])
		@schedule_states = []
		Schedule.states.each do |sst|
			@schedule_states << sst.to_s
		end
		@schedule_states = @schedule_states - @version_control.already_defined_schedule_states
		# add back the current record project_state since it is already been filtered out
		@schedule_states << @version_control_branch.project_status
  end

  # POST /version_control_branches
  # POST /version_control_branches.json
  def create
    @version_control_branch = VersionControlBranch.new(params[:version_control_branch])
		@version_control_branch.version_control_id = @version_control.id

    respond_to do |format|
      if @version_control_branch.save
        format.html { redirect_to [@project,@version_control], notice: 'Version control branch was successfully created.' }
        format.json { render json: @version_control_branch, status: :created, location: @version_control_branch }
      else
        format.html { render action: "new" }
        format.json { render json: @version_control_branch.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /version_control_branches/1
  # PUT /version_control_branches/1.json
  def update
    @version_control_branch = VersionControlBranch.find(params[:id])

    respond_to do |format|
      if @version_control_branch.update_attributes(params[:version_control_branch])
        format.html { redirect_to [@project,@version_control], notice: 'Version control branch was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @version_control_branch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /version_control_branches/1
  # DELETE /version_control_branches/1.json
  def destroy
    @version_control_branch = VersionControlBranch.find(params[:id])
    @version_control_branch.destroy

    respond_to do |format|
      format.html { redirect_to [@project,@version_control] }
      format.json { head :no_content }
    end
  end
end
