class CommitsController < ApplicationController
  before_filter :find_type
  def find_type
    @committable = nil
    if params[:develement_id] != nil
      @committable = Develement.find params[:develement_id]
    elsif params[:issue_id] != nil
      @committable = Issue.find params[:issue_id]
    elsif params[:project_id] != nil
      @committable = Project.find params[:project_id]
    else
      raise ActionController::RoutingError.new("Not Found")
    end
  end

  # GET /commits
  # GET /commits.json
  def index
    #@commits = Commit.all
    @commits = @committable.commits

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @commits }
    end
  end

  # GET /commits/1
  # GET /commits/1.json
  def show
    @commit = Commit.find(params[:id])
		if @commit.repository_url != nil and not @commit.repository_url.empty? and Dir.exist?(@commit.repository_url)
			if @commit.dvcs_provider != nil and @commit.dvcs_provider.downcase == "git"
				@changes = `cd #{@commit.repository_url} && git show #{@commit.identifier}`
				@changes = format_git_changes(@changes)	
			else
				@changes = "<p style=\"color:red\">Unknown DVCS provider #{@commit.dvcs_provider}. Changeset failed to be extracted.<p/>"
			end
		else
			@changes = "<p style=\"color:red\">Path #{@commit.repository_url} is not available. Changeset failed to be extracted.<p/>"
		end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @commit }
    end
  end

  # GET /commits/new
  # GET /commits/new.json
  def new
    @commit = Commit.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @commit }
    end
  end

  # GET /commits/1/edit
  def edit
    @commit = Commit.find(params[:id])
  end

  # POST /commits
  # POST /commits.json
  def create
    @commit = Commit.new(params[:commit])

    respond_to do |format|
      if @commit.save
        format.html { redirect_to @commit, notice: 'Commit was successfully created.' }
        format.json { render json: @commit, status: :created, location: @commit }
      else
        format.html { render action: "new" }
        format.json { render json: @commit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /commits/1
  # PUT /commits/1.json
  def update
    @commit = Commit.find(params[:id])

		@saved = false
		@committable.commits.each do |c|
			c.repository_url = params[:repository_url]
			@saved = c.save
		end

    respond_to do |format|
      #if @commit.update_attributes(params[:commit])
      if @saved
				format.html { redirect_to [@committable.project,@committable,@commit], notice: 'Commit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @commit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /commits/1
  # DELETE /commits/1.json
  def destroy
    @commit = Commit.find(params[:id])
    @commit.destroy

    respond_to do |format|
      format.html { redirect_to commits_url }
      format.json { head :no_content }
    end
  end

	private
	def format_git_changes(changes)
		formatted = changes.gsub("\n","<br/>")
		formatted
	end
end
