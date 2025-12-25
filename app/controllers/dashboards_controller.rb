# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :set_locations, :ensure_default_locations

  def index
  end

  def trends
  end

  def forecasts
  end

  def environment
  end

  def sync_weather
    SyncWeatherJob.perform_now
    redirect_to dashboards_path, notice: "Weather data syncing in progress..."
  end

  private

  def set_locations
    @locations = Location.sorted
  end

  def ensure_default_locations
    return if Location.any?

    default_locations = [
      { name: "San Francisco", latitude: 37.7749, longitude: -122.4194, timezone: "America/Los_Angeles", country: "US", description: "Tech hub" },
      { name: "London", latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London", country: "GB", description: "Historic capital" },
      { name: "Tokyo", latitude: 35.6762, longitude: 139.6503, timezone: "Asia/Tokyo", country: "JP", description: "Modern metropolis" }
    ]

    default_locations.each do |loc_attrs|
      Location.create!(loc_attrs)
    end

    SyncWeatherJob.perform_now
  end
end
