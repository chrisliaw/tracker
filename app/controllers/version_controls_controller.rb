class VersionControlsController < ApplicationController
  before_filter :load_project, :find_variance
  def load_project
    @project = Project.find params[:project_id]
  end

  def find_variance
    @variance = Variance.find params[:variance_id] if params[:variance_id] != nil
  end

  # GET /version_controls
  # GET /version_controls.json
  def index
    #@version_controls = VersionControl.all
    if @variance != nil
      @version_controls = @variance.version_controls
    else
      @version_controls = @project.version_controls
    end 

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @version_controls }
    end
  end

  # GET /version_controls/1
  # GET /version_controls/1.json
  def show
    @version_control = VersionControl.find(params[:id])
		@version_control.notes = "" if @version_control.notes == nil

		@upstreamVcsClass = DvcsConfig.find(@version_control.upstream_vcs_class) if @version_control.upstream_vcs_class != nil and not @version_control.upstream_vcs_class.empty?
		@vcsClass = DvcsConfig.find(@version_control.vcs_class) if @version_control.vcs_class != nil and not @version_control.vcs_class.empty?

    @actions = []
    @version_control.possible_events.each do |evt|
      @actions << evt.to_s
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @version_control }
    end
  end

  # GET /version_controls/new
  # GET /version_controls/new.json
  def new
    @version_control = VersionControl.new
		@dvcs = DvcsConfig.all
    if @variance != nil
      @version_control.versionable = @variance
    else
      @version_control.versionable = @project
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @version_control }
    end
  end

  # GET /version_controls/1/edit
  def edit
    @version_control = VersionControl.find(params[:id])
		@dvcs = DvcsConfig.all
  end

  # POST /version_controls
  # POST /version_controls.json
  def create
    @version_control = VersionControl.new(params[:version_control])
    if @variance != nil
      @version_control.versionable = @variance
    else
      @version_control.versionable = @project
    end

    respond_to do |format|
      if @version_control.save
        #format.html { redirect_to @version_control, notice: 'Version control was successfully created.' }
        if @variance != nil
          format.html { redirect_to [@project,@variance,@version_control], notice: 'Version control for variance was successfully created.' }
        else
          format.html { redirect_to [@project,@version_control], notice: 'Version control for project was successfully created.' }
        end 
        format.json { render json: @version_control, status: :created, location: @version_control }
      else
        format.html { render action: "new" }
        format.json { render json: @version_control.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /version_controls/1
  # PUT /version_controls/1.json
  def update
    @version_control = VersionControl.find(params[:id])

    respond_to do |format|
      if @version_control.update_attributes(params[:version_control])
        #format.html { redirect_to @version_control, notice: 'Version control was successfully updated.' }
        format.html { redirect_to [@project,@version_control], notice: 'Version control was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @version_control.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /version_controls/1
  # DELETE /version_controls/1.json
  def destroy
    @version_control = VersionControl.find(params[:id])
    @version_control.destroy

    respond_to do |format|
			format.html { redirect_to project_version_controls_path(@project) }
      format.json { head :no_content }
    end
  end

  def update_status
    @version_control = VersionControl.find(params[:id])
    act = params[:event]
    puts "act #{act}"
    @version_control.send "#{act}!"
    @version_control.save
    redirect_to [@project,@version_control]
  end

end
