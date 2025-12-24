class LocationsController < ApplicationController
  before_action :set_location, only: :destroy

  def index
    @locations = Location.all
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      SyncWeatherJob.perform_later
      redirect_to locations_path, notice: "Location added successfully"
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy
    redirect_to locations_path, notice: "Location removed successfully"
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :latitude, :longitude, :timezone, :description)
  end
end
