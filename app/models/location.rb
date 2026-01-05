# frozen_string_literal: true

class Location < ApplicationRecord
  # Associations
  has_many :weather_metrics, dependent: :destroy
  has_many :hourly_forecasts, dependent: :destroy
  has_many :historical_weathers, dependent: :destroy
  has_many :marine_weathers, dependent: :destroy
  has_many :air_qualities, dependent: :destroy
  has_many :flood_risks, dependent: :destroy
  has_many :environmental_sensors, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :latitude, :longitude, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  # Callbacks - Update geometry when coordinates change
  before_save :update_geom_from_coordinates, if: :coordinates_changed?

  # Scopes
  scope :sorted, -> { order(:name) }

  # Spatial scope: Find locations within radius of a point
  # radius_km: distance in kilometers
  scope :near_point, lambda { |lat, lng, radius_km = 10|
    if connection.adapter_name.downcase.include?("postgis")
      # PostGIS spatial query (accurate, works on sphere)
      where(
        "ST_DWithin(geom, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
        lng, lat, radius_km * 1000
      )
    else
      # Fallback for non-PostGIS databases (less accurate, uses flat approximation)
      lat_delta = radius_km / 111.0
      lng_delta = radius_km / (111.0 * Math.cos(lat * Math::PI / 180))
      where(
        "(latitude BETWEEN ? AND ?) AND (longitude BETWEEN ? AND ?)",
        lat - lat_delta, lat + lat_delta,
        lng - lng_delta, lng + lng_delta
      )
    end
  }

  # Spatial scope: Find locations within a bounding box
  scope :within_bounds, lambda { |sw_lat, sw_lng, ne_lat, ne_lng|
    where(
      "latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?",
      sw_lat, ne_lat, sw_lng, ne_lng
    )
  }

  # Weather Metrics Methods
  def latest_weather
    weather_metrics.order(recorded_at: :desc).first
  end

  def weather_metrics_24h
    weather_metrics
      .where("recorded_at > ?", 24.hours.ago)
      .order(:recorded_at)
  end

  def weather_metrics_7d
    weather_metrics
      .where("recorded_at > ?", 7.days.ago)
      .order(:recorded_at)
  end

  # Hourly Forecast Methods
  def hourly_forecast_24h
    hourly_forecasts
      .where("forecast_time > ? AND forecast_time < ?", Time.current, 24.hours.from_now)
      .order(:forecast_time)
  end

  # Historical Weather Methods
  def historical_weather_10d
    historical_weathers
      .where("weather_date > ?", 10.days.ago)
      .order(:weather_date)
  end

  # Marine Weather Methods
  def latest_marine_weather
    marine_weathers.order(recorded_at: :desc).first
  end

  # Air Quality Methods
  def latest_air_quality
    air_qualities.order(recorded_at: :desc).first
  end

  def aqi_level_name
    case latest_air_quality&.aqi_level
    when 1
      "Good"
    when 2
      "Fair"
    when 3
      "Moderate"
    when 4
      "Poor"
    when 5
      "Very Poor"
    else
      "N/A"
    end
  end

  # Flood Risk Methods
  def latest_flood_risk
    flood_risks.order(recorded_at: :desc).first
  end

  # GIS Methods
  def has_geom?
    geom.present?
  end

  def active_sensors
    environmental_sensors.where(status: "active")
  end

  def latest_sensor_readings
    environmental_sensors.includes(:environmental_readings)
                         .map(&:latest_reading)
                         .compact
  end

  # Calculate distance to another location in kilometers
  def distance_to(other_location)
    return nil unless has_geom? && other_location.has_geom?

    if self.class.connection.adapter_name.downcase.include?("postgis")
      # Use PostGIS ST_Distance (returns meters)
      result = self.class.connection.select_one(
        self.class.sanitize_sql_array([
          "SELECT ST_Distance(
            ST_GeomFromText(?, 4326)::geography,
            ST_GeomFromText(?, 4326)::geography
          ) as distance",
          geom.as_text,
          other_location.geom.as_text
        ])
      )
      (result["distance"].to_f / 1000.0).round(2)
    else
      # Haversine formula fallback
      haversine_distance(other_location)
    end
  end

  private

  def coordinates_changed?
    latitude_changed? || longitude_changed?
  end

  def update_geom_from_coordinates
    if latitude.present? && longitude.present?
      self.geom = "POINT(#{longitude} #{latitude})"
    end
  end

  # Haversine formula for distance calculation (fallback)
  def haversine_distance(other_location)
    earth_radius_km = 6371.0

    lat1_rad = latitude * Math::PI / 180
    lat2_rad = other_location.latitude * Math::PI / 180
    delta_lat = (other_location.latitude - latitude) * Math::PI / 180
    delta_lng = (other_location.longitude - longitude) * Math::PI / 180

    a = Math.sin(delta_lat / 2)**2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(delta_lng / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    (earth_radius_km * c).round(2)
  end
end
