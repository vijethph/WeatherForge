class Location < ApplicationRecord
  has_many :weather_metrics, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :latitude, :longitude, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

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
end
