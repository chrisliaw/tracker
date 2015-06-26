class ProjectsController < ApplicationController
  # GET /projects
  # GET /projects.json
  def index
		@tag = params[:tag]
		@filter_status = params[:status]
		if @tag != nil
			@projects = Project.where(["category_tags like ? or category_tags like ? or category_tags like ? or category_tags like ?","#{@tag}","%,#{@tag},%","#{@tag},%","%,#{@tag}"]).order(:name)
		else
			if @filter_status != nil
				@projects = Project.where(["state = ?",@filter_status]).order(:name)
			else
				@projects = Project.where(["state = ? or state = ?","active","evaluation"]).order(:name)
				@filter_status = -1
			end
		end

    # status filter combo content
    @status = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Status")
    @status << opt

    opt = FilterType.new("Status")
    statuses = Project.states.collect! {|e| e.to_s }
    statuses.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
		opt << d.new(-1,"Active or Evaluation")
    @status << opt
    # end status filter combo content

    # category filter combo content
    @category = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Category")
    @category << opt

    opt = FilterType.new("Category")
    cats = Project.tags.collect! {|e| e.to_s }
    cats.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
		opt << d.new(-1,"No Category")
    @category << opt
    # end category filter combo content


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])
		@var = params[:vars]

    @actions = []
    @project.possible_events.each do |evt|
      @actions << evt.to_s
    end

    #if params[:format] != "json"
    #  # loading statistic table of Develement    
    #  @stat = {}
    #  @ttl_stat = {}
    #  dev = Develement.count :conditions => ["develement_type_id is null and project_id = ? and variance_parent_id is null",@project.id]
    #  @stat["Unclassified"] = {}
    #  @stat["Unclassified"][:stat] = dev
    #  @stat["Unclassified"][:id] = -1
    #  Develement.states.each do |st|
    #    stst = Develement.count :conditions => ["develement_type_id is null and project_id = ? and state = ? and variance_parent_id is null",@project.id,st.to_s]
    #    @stat["Unclassified"][st] = stst
    #    stst = Develement.count :conditions => ["project_id = ? and state = ? and variance_parent_id is null",@project.id,st.to_s]
    #    @ttl_stat[st] = {}
    #    @ttl_stat[st][:total] = stst
    #  end

    #  DevelementType.all.each do |dt|
    #    @stat[dt.name] = {}
    #    dev = Develement.count :conditions => ["develement_type_id = ? and project_id = ? and variance_parent_id is null",dt.id,@project.id]
    #    @stat[dt.name][:stat] = dev
    #    @stat[dt.name][:id] = dt.id
    #    Develement.states.each do |st|
    #      stst = Develement.count :conditions => ["develement_type_id = ? and project_id = ? and state = ? and variance_parent_id is null",dt.id,@project.id,st.to_s]
    #      @stat[dt.name][st] = stst
    #    end
    #  end
    #  # done loading statistic table for Develement

    #  # loading statistic for Issue table
    #  @stat2 = {}
    #  @ttl_stat2 = {}
    #  issue = Issue.count :conditions => ["issue_type_id is null and project_id = ?",@project.id]
    #  @stat2["Unclassified"] = {}Fun
    #  @stat2["Unclassified"][:stat] = issue
    #  @stat2["Unclassified"][:id] = -1
    #  Issue.states.each do |st|
    #    stst = Issue.count :conditions => ["issue_type_id is null and project_id = ? and state = ?",@project.id,st.to_s]
    #    @stat2["Unclassified"][st] = stst
    #    stst = Issue.count :conditions => ["project_id = ? and state = ?",@project.id,st.to_s]
    #    @ttl_stat2[st] = {}
    #    @ttl_stat2[st][:total] = stst
    #  end
    #  IssueType.all.each do |it|
    #    @stat2[it.name] = {}
    #    issue = Issue.count :conditions => ["issue_type_id = ? and project_id = ?",it.id,@project.id]
    #    @stat2[it.name][:stat] = issue
    #    @stat2[it.name][:id] = it.id
    #    Issue.states.each do |st|
    #      stst = Issue.count :conditions => ["issue_type_id = ? and project_id = ? and state = ?",it.id,@project.id,st.to_s]
    #      @stat2[it.name][st] = stst
    #    end
    #  end
    #  # done loading statistic for issue table
    #end

    respond_to do |format|
      format.html { # show.html.erb 
				#dev_stat(@project.id,@var)
				#issue_stat(@project)
			}
      format.json { render json: @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])
    @project.created_by = session[:user][:login]
		@project.code = @project.code.upcase if @project.code != nil

		catTags = @project.category_tags
		if catTags != nil and not catTags.empty?
			# to smoothen the search by wildcard?
			s = catTags.split(",")
			s = s.collect { |ss| ss.strip }
			@project.category_tags = s.join(",")
		end

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project = Project.find(params[:id])
		params[:project][:code] = params[:project][:code].upcase if params[:project][:code] != nil

		catTags = params[:project][:category_tags]
		if catTags != nil and not catTags.empty?
			# to smoothen the search by wildcard?
			s = catTags.split(",")
			s = s.collect { |ss| ss.strip }
			params[:project][:category_tags] = s.join(",")
		end

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end

  # Display summary table of the project
  def summary
    @project = Project.find(params[:id])
  end

  def update_status
    @project = Project.find(params[:id])
    act = params[:event]
    puts "act #{act}"
    @project.send "#{act}!"
    @project.save
    redirect_to @project
  end

	def project_stat
		@project = Project.find params[:id]	
		@var = params[:vars]

		# build variances drop down
		#@variances = []
		#d = Struct.new(:id,:name)
		#vopt = FilterType.new("No Filter")
		#vopt << d.new(nil,"All Variances")
		#@variances << vopt
		#vopt = FilterType.new("Variances")
		#@project.variances.each do |v|
		#	vopt << d.new(v.id,"#{v.name.titleize}")
		#end
		#@variances << vopt
		# done variances drop down

		dev_stat(@project.id,@var)
		issue_stat(@project)

		respond_to do |format|
			format.html { render :partial => "project_stat" }
			format.js { }
		end
	end

	def dev_stat
		@project = Project.find params[:id]
		@var = params[:vars]

		# build variances drop down
		@variances = []
		d = Struct.new(:id,:name)
		vopt = FilterType.new("No Filter")
		vopt << d.new(nil,"All Variances")
		@variances << vopt
		vopt = FilterType.new("Variances")
		@project.variances.each do |v|
			vopt << d.new(v.id,"#{v.name.titleize}")
		end
		@variances << vopt
		# done variances drop down

		# loading statistic table of Develement    
		@stat = {}
		@ttl_stat = {}
		@grandTtl = 0
		@variance = Variance.find @var if (@var != nil and not @var.empty?)

		conds = []
		conds.add_condition!(["project_id = ?",@project.id])
		# find the unclassified dev items first
		# If variance id not given, find the develement of variance root only
		if @variance == nil
			conds.add_condition!("variance_parent_id is null")
		else
			conds.add_condition!(["variance_id = ?",@variance.id])
		end

		if @schedule == nil
		else
			conds.add_condition!(["schedule_id = ?",@schedule.id])
		end

		noClassStateConds = conds.clone
		noClassStateConds.add_condition!("develement_type_id is null")
		#dev = Develement.count :conditions => ["develement_type_id is null and project_id = ? and variance_parent_id is null",@project.id]
		dev = Develement.count :conditions => noClassStateConds
		@stat["Unclassified"] = {}
		@stat["Unclassified"][:stat] = dev
		@stat["Unclassified"][:id] = -1
		Develement.states.each do |st|
			# find the unclassified item of this particular states...
			stateNoClassStateConds = noClassStateConds.clone
			stateNoClassStateConds.add_condition!(["state = ?",st.to_s])
			#stst = Develement.count :conditions => ["develement_type_id is null and project_id = ? and state = ? and variance_parent_id is null",@project.id,st.to_s]
			stst = Develement.count :conditions => stateNoClassStateConds
			@stat["Unclassified"][st] = stst
			# find the total item of specific state for particular classification
			stateConds = conds.clone
			stateConds.add_condition!(["state = ?",st.to_s])
			#stst = Develement.count :conditions => ["project_id = ? and state = ? and variance_parent_id is null",@project.id,st.to_s]
			stst = Develement.count :conditions => stateConds
			@ttl_stat[st] = {}
			@ttl_stat[st][:total] = stst
			@grandTtl += stst
		end

		DevelementType.all.each do |dt|
			@stat[dt.name] = {}
			devTypeConds = conds.clone
			devTypeConds.add_condition!(["develement_type_id = ?",dt.id])
			#dev = Develement.count :conditions => ["develement_type_id = ? and project_id = ? and variance_parent_id is null",dt.id,@project.id]
			dev = Develement.count :conditions => devTypeConds
			@stat[dt.name][:stat] = dev
			@stat[dt.name][:id] = dt.id
			Develement.states.each do |st|
				devTypeStateConds = devTypeConds.clone
				devTypeStateConds.add_condition!(["state = ?",st.to_s])
				#stst = Develement.count :conditions => ["develement_type_id = ? and project_id = ? and state = ? and variance_parent_id is null",dt.id,@project.id,st.to_s]
				stst = Develement.count :conditions => devTypeStateConds
				@stat[dt.name][st] = stst
			end
		end
		# done loading statistic table for Develement

		respond_to do |format|
			format.html { render :partial => "dev_stat" }
		end
	end

	def issue_stat
		@project = Project.find params[:id]
		@var2 = params[:vars2]

		# build variances drop down
		@variances = []
		d = Struct.new(:id,:name)
		vopt = FilterType.new("No Filter")
		vopt << d.new(nil,"All Variances")
		@variances << vopt
		vopt = FilterType.new("Variances")
		@project.variances.each do |v|
			vopt << d.new(v.id,"#{v.name.titleize}")
		end
		@variances << vopt
		# done variances drop down

		# loading statistic for Issue table
		@stat2 = {}
		@ttl_stat2 = {}
		issue = Issue.count :conditions => ["issue_type_id is null and project_id = ?",@project.id]
		@stat2["Unclassified"] = {}
		@stat2["Unclassified"][:stat] = issue
		@stat2["Unclassified"][:id] = -1
		Issue.states.each do |st|
			stst = Issue.count :conditions => ["issue_type_id is null and project_id = ? and state = ?",@project.id,st.to_s]
			@stat2["Unclassified"][st] = stst
			stst = Issue.count :conditions => ["project_id = ? and state = ?",@project.id,st.to_s]
			@ttl_stat2[st] = {}
			@ttl_stat2[st][:total] = stst
		end
		IssueType.all.each do |it|
			@stat2[it.name] = {}
			issue = Issue.count :conditions => ["issue_type_id = ? and project_id = ?",it.id,@project.id]
			@stat2[it.name][:stat] = issue
			@stat2[it.name][:id] = it.id
			Issue.states.each do |st|
				stst = Issue.count :conditions => ["issue_type_id = ? and project_id = ? and state = ?",it.id,@project.id,st.to_s]
				@stat2[it.name][st] = stst
			end
		end
		# done loading statistic for issue table

		respond_to do |format|
			format.html { render :partial => "issue_stat" }
		end
	end

  def filter_project
		@tag = params[:tag]
		@filter_status = params[:status]
		if @tag != nil and not @tag.empty?
			if @tag == "-1"
				if @filter_status != nil and not @filter_status.empty?
					if @filter_status == "-1"
						@projects = Project.where(["(category_tags is null or category_tags = '') and (state = ? or state = ?)","active","evaluation"]).order(:name)
					else
						@projects = Project.where(["(category_tags is null or category_tags = '') and state = ?",@filter_status]).order(:name)
					end
				else
					@projects = Project.where(["(category_tags is null or category_tags = '')"]).order(:name)
				end

			else
				if @filter_status != nil and not @filter_status.empty?
					if @filter_status == "-1"
						@projects = Project.where(["(category_tags like ? or category_tags like ? or category_tags like ? or category_tags like ?) and (state = ? or state = ?)","#{@tag}","%,#{@tag},%","#{@tag},%","%,#{@tag}","active","evaluation"]).order(:name)
					else
						@projects = Project.where(["(category_tags like ? or category_tags like ? or category_tags like ? or category_tags like ?) and state = ?","#{@tag}","%,#{@tag},%","#{@tag},%","%,#{@tag}",@filter_status]).order(:name)
					end
				else
					@projects = Project.where(["category_tags like ? or category_tags like ? or category_tags like ? or category_tags like ?","#{@tag}","%,#{@tag},%","#{@tag},%","%,#{@tag}"]).order(:name)
				end
			end
		else
			if @filter_status != nil and not @filter_status.empty?
				if @filter_status == "-1"
					@projects = Project.where(["state = ? or state = ?","active","evaluation"]).order(:name)
				else
					@projects = Project.where(["state = ?",@filter_status]).order(:name)
				end
			else
				@projects = Project.all :order => :name
			end
		end

    # status filter combo content
    @status = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Status")
    @status << opt

    opt = FilterType.new("Status")
    statuses = Project.states.collect! {|e| e.to_s }
    statuses.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
		opt << d.new(-1,"Active or Evaluation")
    @status << opt
    # end status filter combo content
		#
    # category filter combo content
    @category = []
    d = Struct.new(:id,:name)
    opt = FilterType.new("No Filter")
    opt << d.new(nil,"All Category")
    @category << opt

    opt = FilterType.new("Category")
    cats = Project.tags.collect! {|e| e.to_s }
    cats.sort.each do |st|
      opt << d.new(st,"#{st.titleize}")
    end 
		opt << d.new(-1,"No Category")
    @category << opt
    # end category filter combo content

    #respond_to do |format|
    #  format.html # 
    #  format.json { render json: @projects }
    #end
		render :layout => false
  end

end
