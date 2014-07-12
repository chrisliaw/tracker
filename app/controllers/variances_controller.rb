class VariancesController < ApplicationController

  before_filter :find_project
  def find_project
    @project = Project.find params[:project_id]
  end

  # GET /variances
  # GET /variances.json
  def index
    #@variances = Variance.all
    @variances = @project.variances

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @variances }
    end
  end

  # GET /variances/1
  # GET /variances/1.json
  def show
    @variance = Variance.find(params[:id])

    @actions = []
    @variance.possible_events.each do |evt|
      @actions << evt.to_s
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @variance }
    end
  end

  # GET /variances/new
  # GET /variances/new.json
  def new
    @variance = Variance.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @variance }
    end
  end

  # GET /variances/1/edit
  def edit
    @variance = Variance.find(params[:id])
  end

  # POST /variances
  # POST /variances.json
  def create
    @variance = Variance.new(params[:variance])
    @variance.project = @project

    respond_to do |format|
      if @variance.save
        format.html { redirect_to project_variances_path(@project), notice: 'Variance was successfully created.' }
        #format.html { redirect_to @variance, notice: 'Variance was successfully created.' }
        format.json { render json: @variance, status: :created, location: @variance }
      else
        format.html { render action: "new" }
        format.json { render json: @variance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /variances/1
  # PUT /variances/1.json
  def update
    @variance = Variance.find(params[:id])

    respond_to do |format|
      if @variance.update_attributes(params[:variance])
        format.html { redirect_to [@project,@variance], notice: 'Variance was successfully updated.' }
        #format.html { redirect_to @variance, notice: 'Variance was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @variance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /variances/1
  # DELETE /variances/1.json
  def destroy
    @variance = Variance.find(params[:id])
    @variance.destroy

    respond_to do |format|
      format.html { redirect_to project_variances_path(@project) }
      format.json { head :no_content }
    end
  end

  def update_status
    @variance = Variance.find(params[:id])
    event = params[:event]
    @variance.send "#{event}!"
    @variance.save
    redirect_to [@project,@variance]
  end
end
