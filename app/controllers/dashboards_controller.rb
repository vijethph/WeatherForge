class DashboardsController < ApplicationController
  before_action :set_locations, only: :index

  def index
    @locations = Location.all.order(:name)
    @weather_metrics = WeatherMetric.last_24_hours.group_by(&:location_id)
  end

  def sync_weather
    SyncWeatherJob.perform_later
    redirect_to root_path, notice: "Weather sync started. Data will update in a few moments."
  end

  private

  def set_locations
    return if Location.any?

    seed_default_locations
    @locations = Location.all.order(:name)
  end

  def seed_default_locations
    Rails.logger.info("Seeding default locations")

    [
      { name: "San Francisco", latitude: 37.7749, longitude: -122.4194, timezone: "America/Los_Angeles" },
      { name: "London", latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London" },
      { name: "Tokyo", latitude: 35.6762, longitude: 139.6503, timezone: "Asia/Tokyo" }
    ].each do |location_data|
      Location.create!(location_data)
    end
  end
end
