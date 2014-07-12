class SchedulesController < ApplicationController
  before_filter :load_project, :find_variance
  def load_project
    @project = Project.find params[:project_id]
  end
  def find_variance
    @variance = Variance.find params[:variance_id] if params[:variance_id] != nil
  end

  # GET /schedules
  # GET /schedules.json
  def index
    #@schedules = Schedule.all
    if @variance != nil
      @schedules = @variance.schedules
    else
      @schedules = @project.schedules
    end 

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @schedules }
    end
  end

  # GET /schedules/1
  # GET /schedules/1.json
  def show
    @schedule = Schedule.find(params[:id])

    @actions = []
    @schedule.possible_events.each do |evt|
      @actions << evt.to_s
    end

    @stat = {}
    @ttl_stat = {}
    dev = Develement.count :conditions => ["develement_type_id is null and project_id = ? and schedule_id = ?",@project.id, @schedule.id]
    @stat["Unclassified"] = {}
    @stat["Unclassified"][:stat] = dev
    @stat["Unclassified"][:id] = -1
    Develement.states.each do |st|
      stst = Develement.count :conditions => ["develement_type_id is null and project_id = ? and state = ? and schedule_id = ?",@project.id,st.to_s,@schedule.id]
      @stat["Unclassified"][st] = stst
      stst = Develement.count :conditions => ["project_id = ? and state = ? and schedule_id = ?",@project.id,st.to_s,@schedule.id]
      @ttl_stat[st] = {}
      @ttl_stat[st][:total] = stst
    end

    DevelementType.all.each do |dt|
      @stat[dt.name] = {}
      dev = Develement.count :conditions => ["develement_type_id = ? and project_id = ? and schedule_id = ?",dt.id,@project.id,@schedule.id]
      @stat[dt.name][:stat] = dev
      @stat[dt.name][:id] = dt.id
      Develement.states.each do |st|
        stst = Develement.count :conditions => ["develement_type_id = ? and project_id = ? and state = ? and schedule_id = ?",dt.id,@project.id,st.to_s,@schedule.id]
        @stat[dt.name][st] = stst
      end
    end

    @stat2 = {}
    @ttl_stat2 = {}
    issue = Issue.count :conditions => ["issue_type_id is null and project_id = ? and schedule_id = ?",@project.id,@schedule.id]
    @stat2["Unclassified"] = {}
    @stat2["Unclassified"][:stat] = issue
    @stat2["Unclassified"][:id] = -1
    Issue.states.each do |st|
      stst = Issue.count :conditions => ["issue_type_id is null and project_id = ? and state = ? and schedule_id = ?",@project.id,st.to_s,@schedule.id]
      @stat2["Unclassified"][st] = stst
      stst = Issue.count :conditions => ["project_id = ? and state = ? and schedule_id = ?",@project.id,st.to_s,@schedule.id]
      @ttl_stat2[st] = {}
      @ttl_stat2[st][:total] = stst
    end
    IssueType.all.each do |it|
      @stat2[it.name] = {}
      issue = Issue.count :conditions => ["issue_type_id = ? and project_id = ? and schedule_id = ?",it.id,@project.id,@schedule.id]
      @stat2[it.name][:stat] = issue
      @stat2[it.name][:id] = it.id
      Issue.states.each do |st|
        stst = Issue.count :conditions => ["issue_type_id = ? and project_id = ? and state = ? and schedule_id = ?",it.id,@project.id,st.to_s,@schedule.id]
        @stat2[it.name][st] = stst
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @schedule }
    end
  end

  # GET /schedules/new
  # GET /schedules/new.json
  def new
    @schedule = Schedule.new
    if @variance != nil
      @schedule.schedulable = @variance
    else
      @schedule.schedulable = @project
    end


    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @schedule }
    end
  end

  # GET /schedules/1/edit
  def edit
    @schedule = Schedule.find(params[:id])
  end

  # POST /schedules
  # POST /schedules.json
  def create
    @schedule = Schedule.new(params[:schedule])
    if @variance != nil
      @schedule.schedulable = @variance
    else
      @schedule.schedulable = @project
    end

    respond_to do |format|
      if @schedule.save
        #format.html { redirect_to @schedule, notice: 'Schedule was successfully created.' }
        if @schedule.req_src != nil and !@schedule.req_src.empty?
          format.html { redirect_to @schedule.req_src, notice: 'Schedule was successfully created.' }
        else
          if @variance != nil
            format.html { redirect_to project_variance_schedules_path(@project,@variance), notice: 'Schedule for project variance was successfully created.' }
          else
            format.html { redirect_to project_schedules_path(@project), notice: 'Schedule for project was successfully created.' }
          end
        end 
        format.json { render json: @schedule, status: :created, location: @schedule }
      else
        format.html { render action: "new" }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /schedules/1
  # PUT /schedules/1.json
  def update
    @schedule = Schedule.find(params[:id])

    respond_to do |format|
      if @schedule.update_attributes(params[:schedule])
        format.html { redirect_to project_schedule_path(@project,@schedule), notice: 'Schedule was successfully updated.' }
        #format.html { redirect_to @schedule, notice: 'Schedule was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schedules/1
  # DELETE /schedules/1.json
  def destroy
    @schedule = Schedule.find(params[:id])
    @schedule.destroy

    respond_to do |format|
      #format.html { redirect_to schedules_url }
      if @variance != nil
        format.html { redirect_to project_variance_schedules_path(@project,@variance) }
      else
        format.html { redirect_to project_schedules_path(@project) }
      end
      format.json { head :no_content }
    end
  end

  def update_status
    @schedule = Schedule.find(params[:id])
    event = params[:event]
    @schedule.send "#{event}!"
    @schedule.save
    redirect_to project_schedule_path(@project,@schedule)
  end
end
