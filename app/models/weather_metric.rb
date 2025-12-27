# frozen_string_literal: true

class WeatherMetric < ApplicationRecord
  belongs_to :location

  validates :temperature, :recorded_at, :location_id, presence: true
  validates :humidity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :last_24_hours, -> { where("recorded_at > ?", 24.hours.ago) }
  scope :last_7_days, -> { where("recorded_at > ?", 7.days.ago) }

  # Weather code interpretation
  WEATHER_CODES = {
    0 => "Clear sky",
    1 => "Mainly clear",
    2 => "Partly cloudy",
    3 => "Overcast",
    45 => "Foggy",
    48 => "Depositing rime fog",
    51 => "Light drizzle",
    53 => "Moderate drizzle",
    55 => "Dense drizzle",
    61 => "Slight rain",
    63 => "Moderate rain",
    65 => "Heavy rain",
    71 => "Slight snow",
    73 => "Moderate snow",
    75 => "Heavy snow",
    80 => "Slight rain showers",
    81 => "Moderate rain showers",
    82 => "Violent rain showers",
    95 => "Thunderstorm",
    96 => "Thunderstorm with slight hail",
    99 => "Thunderstorm with heavy hail"
  }.freeze

  def weather_description
    WEATHER_CODES[weather_code] || "Unknown"
  end

  def temperature_fahrenheit
    (temperature * 9.0 / 5.0) + 32
  end

  def feels_like_fahrenheit
    return nil unless feels_like

    (feels_like * 9.0 / 5.0) + 32
  end
end
