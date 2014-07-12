class IssueTypesController < ApplicationController
  # GET /issue_types
  # GET /issue_types.json
  def index
    @issue_types = IssueType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @issue_types }
    end
  end

  # GET /issue_types/1
  # GET /issue_types/1.json
  def show
    @issue_type = IssueType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @issue_type }
    end
  end

  # GET /issue_types/new
  # GET /issue_types/new.json
  def new
    @issue_type = IssueType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @issue_type }
    end
  end

  # GET /issue_types/1/edit
  def edit
    @issue_type = IssueType.find(params[:id])
  end

  # POST /issue_types
  # POST /issue_types.json
  def create
    @issue_type = IssueType.new(params[:issue_type])

    respond_to do |format|
      if @issue_type.save
        format.html { redirect_to @issue_type, notice: 'Issue type was successfully created.' }
        format.json { render json: @issue_type, status: :created, location: @issue_type }
      else
        format.html { render action: "new" }
        format.json { render json: @issue_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /issue_types/1
  # PUT /issue_types/1.json
  def update
    @issue_type = IssueType.find(params[:id])

    respond_to do |format|
      if @issue_type.update_attributes(params[:issue_type])
        format.html { redirect_to @issue_type, notice: 'Issue type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @issue_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issue_types/1
  # DELETE /issue_types/1.json
  def destroy
    @issue_type = IssueType.find(params[:id])
    @issue_type.destroy

    respond_to do |format|
      format.html { redirect_to issue_types_url }
      format.json { head :no_content }
    end
  end
end
