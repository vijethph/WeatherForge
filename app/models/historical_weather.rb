# frozen_string_literal: true

class HistoricalWeather < ApplicationRecord
  belongs_to :location

  validates :weather_date, :location_id, presence: true
  validates :weather_date, uniqueness: { scope: :location_id }

  scope :recent, -> { order(weather_date: :desc) }
  scope :last_10_days, -> { where("weather_date > ?", 10.days.ago).order(:weather_date) }

  # Weather code interpretation (shared with WeatherMetric)
  WEATHER_CODES = WeatherMetric::WEATHER_CODES

  def weather_description
    WEATHER_CODES[weather_code] || "Unknown"
  end
end
