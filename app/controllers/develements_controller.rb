class DevelementsController < ApplicationController

  layout proc { |c| c.request.xhr? ? false : "application"}
  before_filter :load_project
  def load_project
    @project = Project.find params[:project_id]
  end

  # GET /develements
  # GET /develements.json
  def index
    @state = params[:state]
    @cls = params[:class]
    @kw = params[:keyword]
    @sch = params[:schedule]
    @var = params[:variance]
    @develements,@ttlCnt = filter_record(@state,@cls,@kw,@sch,@var,params[:page])
    #@develements = @project.develements

    # status filter combo content
    @status = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Status")
    @status << opt

    opt = FilterType.new("Status")
    statuses = Develement.states.collect! {|e| e.to_s }
    statuses.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
    @status << opt
    # end status filter combo content

    # classification filter combo content
    @class = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Classification")
    @class << opt

    opt = FilterType.new("Classification")
    opt << d.new(-1,"Unclassified")
    DevelementType.all.each do |dt|
      opt << d.new(dt.id,dt.name)
    end
    @class << opt
    # end classification combo content

    # schedule filter combo content
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
    # end schedule filter combo content

    # variance filter combo content
    @variances = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Variances")
    @variances << opt    
    opt = FilterType.new("Variance")
    opt << d.new(-1,"No Variance")
    @project.variances.each do |sc|
      opt << d.new(sc.id,sc.name)
    end
    @variances << opt
    # end variance filter combo content

   respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @develements }
    end
  end

  # GET /develements/1
  # GET /develements/1.json
  def show
    @develement = Develement.find(params[:id])

    @actions = []
    @develement.possible_events.each do |evt|
      @actions << evt.to_s
    end

    respond_to do |format|    
      format.html # show.html.erb
      format.json { render json: @develement }
    end
  end

  # GET /develements/new
  # GET /develements/new.json
  def new
    @develement = Develement.new
    @develement.project = @project
    @devType = DevelementType.all

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @develement }
    end
  end

  # GET /develements/1/edit
  def edit
    @develement = Develement.find(params[:id])    
    @devType = DevelementType.all
    @childrenId = []
    @develement.variance_children.each do |c|
      @childrenId << c.variance_id
    end
  end

  # POST /develements
  # POST /develements.json
  def create
    @develement = Develement.new(params[:develement])
    @develement.variance_id = ""
    @develement.project = @project
		@develement.desc = "" if @develement.desc == nil
		@develement.created_by = session[:user][:login] if not request.format == "json"

    if params[:develement][:variance_id] != nil
      params[:develement][:variance_id].each do |v|
        d = Develement.new(params[:develement])
        d.project = @project
        d.variance_id = v
        # reset schedule?
        #d.schedule_id = nil
        @develement.variance_children << d
      end
    end

    respond_to do |format|
      if @develement.save
        #format.html { redirect_to @develement, notice: 'Develement was successfully created.' }
        format.html { redirect_to project_develements_path(@project), notice: 'Develement was successfully created.' }
        format.json { render json: @develement, status: :created, location: project_develements_path(@project) }
      else
				p @develement.errors
        format.html { render action: "new" }
        format.json { render json: @develement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /develements/1
  # PUT /develements/1.json
  def update
    @develement = Develement.find(params[:id])

    if params[:develement][:variance_id] != nil
      params[:develement][:variance_id].each do |v|
        @develement.variance_children.each do |c|
          c.name = @develement.name
          c.desc = @develement.desc
          c.schedule_id = @develement.schedule_id
        end
      end
    end

    respond_to do |format|
      if @develement.update_attributes(params[:develement])
        format.html { redirect_to [@project,@develement], notice: 'Develement was successfully updated.' }
        #format.html { redirect_to @develement, notice: 'Develement was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @develement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /develements/1
  # DELETE /develements/1.json
  def destroy
    @develement = Develement.find(params[:id])
    parent = @develement.variance_parent
    @develement.destroy

    respond_to do |format|
      #format.html { redirect_to develements_url }
			if parent != nil
				format.html { redirect_to [@project,parent] }
			else
				format.html { redirect_to project_develements_path(@project) }
			end
      format.json { head :no_content }
    end
  end

  def add_variances
    @develement = Develement.find(params[:id])
    @vars = []
    @develement.variance_children.each do |c|
      @vars << c.variance
    end

    @availVars = @project.variances - @vars

    respond_to do |format|    
      format.html # show.html.erb
      format.json { render json: @develement }
    end
  end

  def update_variances
    @develement = Develement.find(params[:id])

    @safe_successful = true
    if params[:develement][:variance_id] != nil
      params[:develement][:variance_id].each do |v|
        d = Develement.new
        d.name = @develement.name
        d.desc = @develement.desc
        d.develement_type_id = @develement.develement_type_id
        #d.created_by = session[:user] 
        d.variance_parent = @develement
        d.project = @project
        d.variance_id = v
        #@develement.variance_children << d
        if !d.save
          @safe_successful = false
          break
        end 
      end
    end

    respond_to do |format|
      if @safe_successful
        #format.html { redirect_to @develement, notice: 'Develement was successfully created.' }
        format.html { redirect_to [@project,@develement], notice: 'Develement was successfully created.' }
        format.json { render json: @develement, status: :created, location: @develement }
      else
        #format.html { render action: "add_variances" }
        format.html { redirect_to action: "add_variances" }
        format.json { render json: @develement.errors, status: :unprocessable_entity }
      end
    end
  end


  def filter_status
    status = params[:status]
    cls = params[:class]
    kw = params[:keyword]
    sch = params[:schedule]
    var = params[:variance]
		@develements = []
    @filter,@ttlCnt = filter_record(status,cls,kw,sch,var,params[:page])
		# TODO this is ineffective!
		if var == "-1"
			@filter.each do |d|
				if d.variance_children.length > 0
				else
					@develements << d
				end
			end
		else
			@develements = @filter
		end
  end

	def batch_process
    @state = params[:state]
    @cls = params[:class]
    @kw = params[:keyword]
    @sch = params[:schedule]
    @var = params[:variance]
    @develements,@ttlCnt = filter_record(@state,@cls,@kw,@sch,@var,params[:page])
    #@develements = @project.develements

    # status filter combo content
    @status = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Status")
    @status << opt

    opt = FilterType.new("Status")
    statuses = Develement.states.collect! {|e| e.to_s }
    statuses.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
    @status << opt
    # end status filter combo content

    # classification filter combo content
    @class = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Classification")
    @class << opt

    opt = FilterType.new("Classification")
    opt << d.new(-1,"Unclassified")
    DevelementType.all.each do |dt|
      opt << d.new(dt.id,dt.name)
    end
    @class << opt
    # end classification combo content

    # schedule filter combo content
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
    # end schedule filter combo content

    # variance filter combo content
    @variances = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Variances")
    @variances << opt    
    opt = FilterType.new("Variance")
    opt << d.new(-1,"No Variance")
    @project.variances.each do |sc|
      opt << d.new(sc.id,sc.name)
    end
    @variances << opt
    # end variance filter combo content

   respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @develements }
    end
	end

	def batch_update_filter
		status = params[:status]
    cls = params[:class]
    kw = params[:keyword]
    sch = params[:schedule]
    var = params[:variance]
		@develements = []
    @filter,@ttlCnt = filter_record(status,cls,kw,sch,var,params[:page])
		# TODO this is ineffective!
		if var == "-1"
			@filter.each do |d|
				if d.variance_children.length > 0
				else
					@develements << d
				end
			end
		else
			@develements = @filter
		end

	end

	def select_batch_update_field
		@selected = params[:develement][:id] if params[:develement] != nil
		if @selected != nil and @selected.length > 0
			@develements = []
			@selected.each do |sel|
				d = Develement.find(sel)
				@status = d.state if @status == nil
				if @status != "-" and @status != d.state
					@status = "-"
					@statuses = []
				else
					@statuses = d.possible_events
				end
				@develements << d
			end

			if @status != "-"
				@statuses = @statuses.collect { |s| s.to_s.titleize }
			end
			@classification = DevelementType.all
			@schedule = @project.schedules
		else
			flash[:error] = "Please select one of the record"
			redirect_to :action => :batch_process
		end		
	end

	def update_batch
		selected = params[:selected]
		newClass = params[:new_class]
		newSchedule = params[:new_schedule]
		newStatus = params[:new_status]
		
		if (newClass != nil and not newClass.empty?) or (newSchedule != nil and not newSchedule.empty?) or (newStatus != nil and not newStatus.empty?)
			sels = selected.split(",")
			sels.each do |sel|
				d = Develement.find(sel)
				d.develement_type_id = newClass if newClass != nil and not newClass.empty?
				d.schedule_id = newSchedule if newSchedule != nil and not newSchedule.empty?
				d.save
				d.send "#{newStatus}!" if newStatus != nil and not newStatus.empty?
			end
			flash[:notice] = "#{sels.length} records updated"
		else
			flash[:notice] = "No new value given. None of the record got updated."
		end

		redirect_to project_develements_path(@project)
	end

  def update_status
    @develement = Develement.find(params[:id])
    event = params[:event]
    @develement.send "#{event}!"

		respond_to do |format|
			format.html { redirect_to [@project,@develement] }
			format.json { head :no_content }
		end
    #redirect_to [@project,@develement]
  end

	def find_by_code
		code = params[:code]
		@develement = Develement.where(["code = ?",code]).first
    respond_to do |format|    
      format.html 
      format.json { render json: @develement }
    end
	end

  private
  def filter_record(state,cls,keyword,schedule,variance,page)

    conds = []
    conds.add_condition!(['project_id = ?',@project.id])
    if state != nil and !state.empty?
      conds.add_condition!(['state = ?',state])
    end

    if cls != nil and !cls.empty?
      if cls == "-1"
        conds.add_condition!('develement_type_id is null')
      else
        conds.add_condition!(['develement_type_id = ?',cls])
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

    if variance != nil and not variance.empty?
      if variance == "-1"
        conds.add_condition!("variance_id is null or variance_id = ''")
      else
        conds.add_condition!(['variance_id = ?',variance])
        #conds.add_condition!('variance_parent_id is null')
      end
    else
      conds.add_condition!('variance_parent_id is null')
    end

    p conds
		#[Develement.where(conds).page(page).per(3), Develement.where(conds).count]
		[Develement.where(conds), Develement.where(conds).count]
    #if state != nil and !state.empty?
    #  if cls != nil and !cls.empty?
    #    if cls == "-1"
    #      @develements = Develement.all :conditions => ["project_id = ? and state = ? and develement_type_id is null",@project.id,state] 
    #    else
    #      @develements = Develement.all :conditions => ["project_id = ? and state = ? and develement_type_id = ?",@project.id,state,cls] 
    #    end
    #  else
    #    @develements = Develement.all :conditions => ["project_id = ? and state = ?",@project.id,state] 
    #  end
    #else
    #  if cls != nil and !cls.empty?
    #    if cls == "-1"
    #      @develements = Develement.all :conditions => ["project_id = ? and develement_type_id is null",@project.id] 
    #    else
    #      @develements = Develement.all :conditions => ["project_id = ? and develement_type_id = ?",@project.id,cls] 
    #    end
    #  else
    #    @develements = Develement.all :conditions => ["project_id = ?",@project.id] 
    #  end
    #end

    #@develements
  end

end
