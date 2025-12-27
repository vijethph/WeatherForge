# frozen_string_literal: true

class HourlyForecast < ApplicationRecord
  belongs_to :location

  validates :forecast_time, :location_id, presence: true
  validates :precipitation_probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  scope :upcoming, -> { where("forecast_time > ?", Time.current).order(:forecast_time) }

  # Weather code interpretation (shared with WeatherMetric)
  WEATHER_CODES = WeatherMetric::WEATHER_CODES

  def weather_description
    WEATHER_CODES[weather_code] || "Unknown"
  end
end
