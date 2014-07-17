class IssuesController < ApplicationController
  layout proc { |c| c.request.xhr? ? false : "application"}
  before_filter :load_project
  def load_project
    @project = Project.find params[:project_id]
  end

  # GET /issues
  # GET /issues.json
  def index
    @state = params[:state]
    @cls = params[:class]
    @kw = params[:keyword]
    @sch = params[:schedule]
    @issues = filter_record(@state,@cls,@kw,@sch)
    #@issues = @project.issues

    @status = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"Show All")
    @status << opt

    opt = FilterType.new("Status")
    statuses = Issue.states.collect! {|e| e.to_s }
    statuses.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
    @status << opt

    @class = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"Show All")
    @class << opt

    opt = FilterType.new("Classification")
    opt << d.new(-1,"Unclassified")
    IssueType.all.each do |dt|
      opt << d.new(dt.id,dt.name)
    end
    @class << opt

    @schedules = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Schedule")
    @schedules << opt

    opt = FilterType.new("Schedule")
    opt << d.new(-1,"Unschedule")
    @project.schedules.each do |sc|
      opt << d.new(sc.id,sc.name)
    end
    @schedules << opt

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @issues }
    end
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
    @issue = Issue.find(params[:id])

    @actions = []
    @issue.possible_events.each do |evt|
      @actions << evt.to_s
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @issue }
    end
  end

  # GET /issues/new
  # GET /issues/new.json
  def new
    @issue = Issue.new
    @issue.project = @project
    @issueType = IssueType.all

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @issue }
    end
  end

  # GET /issues/1/edit
  def edit
    @issue = Issue.find(params[:id])
    @issueType = IssueType.all
  end

  # POST /issues
  # POST /issues.json
  def create
    @issue = Issue.new(params[:issue])
    @issue.project = @project
    @issue.created_by = session[:user][:login]

    respond_to do |format|
      if @issue.save
        #format.html { redirect_to @issue, notice: 'Issue was successfully created.' }
        format.html { redirect_to project_issues_path(@project), notice: 'Issue was successfully created.' }
        format.json { render json: @issue, status: :created, location: @issue }
      else
        format.html { render action: "new" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /issues/1
  # PUT /issues/1.json
  def update
    @issue = Issue.find(params[:id])

    respond_to do |format|
      if @issue.update_attributes(params[:issue])
        format.html { redirect_to [@project,@issue], notice: 'Issue was successfully updated.' }
        #format.html { redirect_to @issue, notice: 'Issue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    @issue = Issue.find(params[:id])
    @issue.destroy

    respond_to do |format|
      format.html { redirect_to issues_url }
      format.json { head :no_content }
    end
  end

  def filter_status
    status = params[:status]
    cls = params[:class]
    kw = params[:keyword]
    sch = params[:schedule]
    @issues = filter_record(status,cls,kw,sch)   
  end

  def update_status
    @issue = Issue.find(params[:id])
    event = params[:event]
    @issue.send "#{event}!"
    #@issue.save

		respond_to do |format|
			format.html { redirect_to [@project,@issue] }
			format.json { head :no_content }
		end
    #redirect_to [@project,@issue]
  end

  private
  def filter_record(state,cls,keyword,schedule)

    conds = []
    conds.add_condition!(['project_id = ?',@project.id])
    if state != nil and !state.empty?
      conds.add_condition!(['state = ?',state])
    end

    if cls != nil and !cls.empty?
      if cls == "-1"
        conds.add_condition!('issue_type_id is null')
      else
        conds.add_condition!(['issue_type_id = ?',cls])
      end
    end

    if keyword != nil and !keyword.empty?
      conds.add_condition!(['name like ?',"%#{keyword}%"])
    end

    if schedule != nil and !schedule.empty?
      if schedule == "-1"
        conds.add_condition!("schedule_id is null or schedule_id = ''")
      else
        conds.add_condition!(['schedule_id = ?',schedule])
      end
    end

   Issue.all :conditions => conds
 
    #if state != nil and !state.empty?
    #  if cls != nil and !cls.empty?
    #    if cls == "-1"
    #      @issues = Issue.all :conditions => ["project_id = ? and state = ? and issue_type_id is null",@project.id,state] 
    #    else
    #      @issues = Issue.all :conditions => ["project_id = ? and state = ? and issue_type_id = ?",@project.id,state,cls] 
    #    end
    #  else
    #    @issues = Issue.all :conditions => ["project_id = ? and state = ?",@project.id,state] 
    #  end
    #else
    #  if cls != nil and !cls.empty?
    #    if cls == "-1"
    #      @issues = Issue.all :conditions => ["project_id = ? and issue_type_id is null",@project.id] 
    #    else
    #      @issues = Issue.all :conditions => ["project_id = ? and issue_type_id = ?",@project.id,cls] 
    #    end
    #  else
    #    @issues = Issue.all :conditions => ["project_id = ?",@project.id] 
    #  end
    #end

    #@issues
  end
end
