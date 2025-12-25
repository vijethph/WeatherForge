# frozen_string_literal: true

class Location < ApplicationRecord
  # Associations
  has_many :weather_metrics, dependent: :destroy
  has_many :hourly_forecasts, dependent: :destroy
  has_many :historical_weathers, dependent: :destroy
  has_many :marine_weathers, dependent: :destroy
  has_many :air_qualities, dependent: :destroy
  has_many :flood_risks, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :latitude, :longitude, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  # Scopes
  scope :sorted, -> { order(:name) }

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
end
