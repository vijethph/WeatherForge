class WeatherMetric < ApplicationRecord
  belongs_to :location

  validates :temperature, :humidity, :wind_speed, :precipitation, presence: true
  validates :recorded_at, presence: true
  validates :location_id, presence: true
  validates :humidity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :recent, -> { order(recorded_at: :desc) }
  scope :last_24_hours, -> { where("recorded_at > ?", 24.hours.ago) }
  scope :last_7_days, -> { where("recorded_at > ?", 7.days.ago) }

  def temperature_fahrenheit
    (temperature * 9 / 5) + 32
  end
end
