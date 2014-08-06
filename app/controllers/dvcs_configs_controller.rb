class DvcsConfigsController < ApplicationController
  # GET /dvcs_configs
  # GET /dvcs_configs.json
  def index
    @dvcs_configs = DvcsConfig.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @dvcs_configs }
    end
  end

  # GET /dvcs_configs/1
  # GET /dvcs_configs/1.json
  def show
    @dvcs_config = DvcsConfig.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @dvcs_config }
    end
  end

  # GET /dvcs_configs/new
  # GET /dvcs_configs/new.json
  def new
    @dvcs_config = DvcsConfig.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dvcs_config }
    end
  end

  # GET /dvcs_configs/1/edit
  def edit
    @dvcs_config = DvcsConfig.find(params[:id])
  end

  # POST /dvcs_configs
  # POST /dvcs_configs.json
  def create
    @dvcs_config = DvcsConfig.new(params[:dvcs_config])

    respond_to do |format|
      if @dvcs_config.save
        format.html { redirect_to @dvcs_config, notice: 'Dvcs config was successfully created.' }
        format.json { render json: @dvcs_config, status: :created, location: @dvcs_config }
      else
        format.html { render action: "new" }
        format.json { render json: @dvcs_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /dvcs_configs/1
  # PUT /dvcs_configs/1.json
  def update
    @dvcs_config = DvcsConfig.find(params[:id])

    respond_to do |format|
      if @dvcs_config.update_attributes(params[:dvcs_config])
        format.html { redirect_to @dvcs_config, notice: 'Dvcs config was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @dvcs_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dvcs_configs/1
  # DELETE /dvcs_configs/1.json
  def destroy
    @dvcs_config = DvcsConfig.find(params[:id])
    @dvcs_config.destroy

    respond_to do |format|
      format.html { redirect_to dvcs_configs_url }
      format.json { head :no_content }
    end
  end
end
