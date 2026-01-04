# frozen_string_literal: true

class LocationsController < ApplicationController
  before_action :set_location, only: :destroy

  def index
    @locations = Location.sorted
    @location = Location.new
    @search_results = []
  end

  def search
    query = params[:query].to_s.strip
    @search_results = if query.length >= 3
                        WeatherService.search_locations(query)
    else
                        []
    end

    respond_to do |format|
      format.json { render json: { results: @search_results } }
      format.html do
        @locations = Location.sorted
        @location = Location.new
        render :index
      end
    end
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      fetch_and_update_elevation
      SyncWeatherJob.perform_later

      redirect_to dashboards_path, notice: "Location added successfully"
    else
      @locations = Location.sorted
      @search_results = []
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    if @location.destroy
      redirect_to dashboards_path, notice: "Location removed successfully"
    else
      Rails.logger.error("Failed to destroy location #{@location.name}: #{@location.errors.full_messages.join(', ')}")
      redirect_to dashboards_path, alert: "Failed to remove location: #{@location.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    Rails.logger.error("Error destroying location #{@location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    redirect_to dashboards_path, alert: "Error removing location: #{e.message}"
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :latitude, :longitude, :timezone, :country, :description)
  end

  def fetch_and_update_elevation
    service = WeatherService.new(@location)
    elevation = service.fetch_elevation

    if elevation.present?
      @location.update(elevation: elevation)
      Rails.logger.info("Elevation fetched for #{@location.name}: #{elevation}m")
    end
  rescue StandardError => e
    Rails.logger.error("Failed to fetch elevation for #{@location.name}: #{e.message}")
  end
end
