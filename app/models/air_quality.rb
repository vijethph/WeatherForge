# frozen_string_literal: true

class AirQuality < ApplicationRecord
  belongs_to :location

  validates :recorded_at, :location_id, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :last_24_hours, -> { where("recorded_at > ?", 24.hours.ago) }

  # AQI Level names
  AQI_LEVELS = {
    1 => "Good",
    2 => "Fair",
    3 => "Moderate",
    4 => "Poor",
    5 => "Very Poor"
  }.freeze

  def aqi_name
    AQI_LEVELS[aqi_level] || "Unknown"
  end
end
