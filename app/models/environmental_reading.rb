# frozen_string_literal: true

class EnvironmentalReading < ApplicationRecord
  # Associations
  belongs_to :environmental_sensor
  has_one :location, through: :environmental_sensor
  has_many :environmental_alerts, dependent: :destroy

  # Validations
  validates :value, presence: true, numericality: true
  validates :unit, presence: true
  validates :recorded_at, presence: true
  validates :environmental_sensor, presence: true

  # Scopes
  scope :recent, -> { order(recorded_at: :desc).limit(100) }
  scope :for_sensor, ->(sensor) { where(environmental_sensor: sensor) }
  scope :in_timerange, ->(start_time, end_time) { where(recorded_at: start_time..end_time) }
  scope :exceeding, ->(threshold) { where("value > ?", threshold) }
  scope :below, ->(threshold) { where("value < ?", threshold) }
  scope :last_24_hours, -> { where("recorded_at > ?", 24.hours.ago) }
  scope :last_7_days, -> { where("recorded_at > ?", 7.days.ago) }

  # Callbacks
  after_create :check_threshold_and_create_alert

  # For time-series charting with Chartkick
  def self.for_chartkick(sensor, hours = 24)
    for_sensor(sensor)
      .in_timerange(hours.hours.ago, Time.current)
      .order(recorded_at: :asc)
      .pluck(:recorded_at, :value)
  end

  # Health classification based on sensor type and value
  def health_level
    case environmental_sensor.sensor_type
    when "air_quality"
      aqi_health_level
    when "pm25"
      pm25_health_level
    when "pm10"
      pm10_health_level
    when "ozone"
      ozone_health_level
    when "no2"
      no2_health_level
    else
      "Unknown"
    end
  end

  # Health level color for UI badges
  def health_level_color
    case health_level
    when "Good" then "success"
    when "Moderate" then "info"
    when "Unhealthy for Sensitive Groups" then "warning"
    when "Unhealthy" then "danger"
    when "Very Unhealthy", "Hazardous" then "danger"
    else "secondary"
    end
  end

  # Check if this reading exceeds safe thresholds
  def exceeds_threshold?
    case environmental_sensor.sensor_type
    when "pm25"
      value > 35.4
    when "pm10"
      value > 154
    when "ozone"
      value > 70
    when "no2"
      value > 100
    when "so2"
      value > 75
    when "co"
      value > 9.4
    else
      false
    end
  end

  private

  def check_threshold_and_create_alert
    return unless exceeds_threshold?

    EnvironmentalAlert.create!(
      environmental_sensor: environmental_sensor,
      environmental_reading: self,
      alert_type: "threshold_exceeded",
      severity: determine_severity,
      message: "#{environmental_sensor.sensor_type.upcase} reading of #{value} #{unit} exceeds safe threshold"
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create alert for reading #{id}: #{e.message}"
  end

  def determine_severity
    case environmental_sensor.sensor_type
    when "pm25"
      value > 150 ? "critical" : (value > 55 ? "high" : "medium")
    when "pm10"
      value > 254 ? "critical" : (value > 254 ? "high" : "medium")
    when "ozone"
      value > 105 ? "critical" : (value > 85 ? "high" : "medium")
    else
      "medium"
    end
  end

  # AQI health level calculations
  def aqi_health_level
    case value
    when 0..50 then "Good"
    when 51..100 then "Moderate"
    when 101..150 then "Unhealthy for Sensitive Groups"
    when 151..200 then "Unhealthy"
    when 201..300 then "Very Unhealthy"
    else "Hazardous"
    end
  end

  def pm25_health_level
    case value
    when 0..12.0 then "Good"
    when 12.1..35.4 then "Moderate"
    when 35.5..55.4 then "Unhealthy for Sensitive Groups"
    when 55.5..150.4 then "Unhealthy"
    when 150.5..250.4 then "Very Unhealthy"
    else "Hazardous"
    end
  end

  def pm10_health_level
    case value
    when 0..54 then "Good"
    when 55..154 then "Moderate"
    when 155..254 then "Unhealthy for Sensitive Groups"
    when 255..354 then "Unhealthy"
    when 355..424 then "Very Unhealthy"
    else "Hazardous"
    end
  end

  def ozone_health_level
    case value
    when 0..54 then "Good"
    when 55..70 then "Moderate"
    when 71..85 then "Unhealthy for Sensitive Groups"
    when 86..105 then "Unhealthy"
    when 106..200 then "Very Unhealthy"
    else "Hazardous"
    end
  end

  def no2_health_level
    case value
    when 0..53 then "Good"
    when 54..100 then "Moderate"
    when 101..360 then "Unhealthy for Sensitive Groups"
    when 361..649 then "Unhealthy"
    when 650..1249 then "Very Unhealthy"
    else "Hazardous"
    end
  end

  def temperature_level
    case value
    when -40..-10 then "Extreme Cold"
    when -9..0 then "Very Cold"
    when 1..10 then "Cold"
    when 11..20 then "Cool"
    when 21..30 then "Comfortable"
    when 31..35 then "Warm"
    when 36..40 then "Hot"
    else "Extreme Heat"
    end
  end
end
