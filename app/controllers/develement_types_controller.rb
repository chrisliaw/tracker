class DevelementTypesController < ApplicationController
  # GET /develement_types
  # GET /develement_types.json
  def index
    @develement_types = DevelementType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @develement_types }
    end
  end

  # GET /develement_types/1
  # GET /develement_types/1.json
  def show
    @develement_type = DevelementType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @develement_type }
    end
  end

  # GET /develement_types/new
  # GET /develement_types/new.json
  def new
    @develement_type = DevelementType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @develement_type }
    end
  end

  # GET /develement_types/1/edit
  def edit
    @develement_type = DevelementType.find(params[:id])
  end

  # POST /develement_types
  # POST /develement_types.json
  def create
    @develement_type = DevelementType.new(params[:develement_type])

    respond_to do |format|
      if @develement_type.save
        format.html { redirect_to @develement_type, notice: 'Develement type was successfully created.' }
        format.json { render json: @develement_type, status: :created, location: @develement_type }
      else
        format.html { render action: "new" }
        format.json { render json: @develement_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /develement_types/1
  # PUT /develement_types/1.json
  def update
    @develement_type = DevelementType.find(params[:id])

    respond_to do |format|
      if @develement_type.update_attributes(params[:develement_type])
        format.html { redirect_to @develement_type, notice: 'Develement type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @develement_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /develement_types/1
  # DELETE /develement_types/1.json
  def destroy
    @develement_type = DevelementType.find(params[:id])
    @develement_type.destroy

    respond_to do |format|
      format.html { redirect_to develement_types_url }
      format.json { head :no_content }
    end
  end
end
