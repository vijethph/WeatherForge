# frozen_string_literal: true

class EnvironmentalSensor < ApplicationRecord
  # Associations
  belongs_to :location, optional: true
  has_many :environmental_readings, dependent: :destroy
  has_many :environmental_alerts, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :sensor_type, presence: true, inclusion: {
    in: %w[air_quality temperature humidity water_quality pm25 pm10 ozone no2 so2 co],
    message: "must be a valid sensor type"
  }
  validates :manufacturer, presence: true
  validates :installation_date, presence: true

  # Validate presence of coordinates only if location is not present
  # (coordinates can be populated from location via callback)
  validate :coordinates_must_be_present_or_location_exists

  validates :latitude, numericality: {
    greater_than_or_equal_to: -90,
    less_than_or_equal_to: 90,
    allow_nil: true
  }
  validates :longitude, numericality: {
    greater_than_or_equal_to: -180,
    less_than_or_equal_to: 180,
    allow_nil: true
  }
  validates :status, presence: true, inclusion: {
    in: %w[active inactive maintenance],
    message: "must be active, inactive, or maintenance"
  }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :in_maintenance, -> { where(status: "maintenance") }
  scope :by_type, ->(type) { where(sensor_type: type) }
  scope :sorted, -> { order(:name) }
  scope :sorted_by_name, -> { order(:name) }

  # Spatial scope: Find sensors within radius of a location
  scope :near_location, lambda { |location, radius_km = 10|
    if location.respond_to?(:geom) && location.geom.present?
      where("ST_DWithin(geom, ?, ?)", location.geom, radius_km * 1000)
    else
      none
    end
  }

  # Callbacks
  before_validation :set_coordinates_from_location_if_blank, if: -> { new_record? && location.present? }
  before_save :update_geom_from_coordinates, if: :coordinates_changed?

  # Check if sensor is currently active
  def active?
    status == "active"
  end

  # Status badge CSS class for UI
  def status_badge_class
    case status
    when "active" then "badge bg-success"
    when "inactive" then "badge bg-secondary"
    when "maintenance" then "badge bg-warning"
    else "badge bg-dark"
    end
  end

  # Latest reading for this sensor
  def latest_reading
    environmental_readings.order(recorded_at: :desc).first
  end

  # Average reading for past N hours
  def average_reading(hours = 24)
    environmental_readings
      .where("recorded_at > ?", hours.hours.ago)
      .average(:value)
      .to_f
      .round(2)
  end

  # Readings for past N hours (for charting)
  def readings_for_period(hours = 24)
    environmental_readings
      .where("recorded_at > ?", hours.hours.ago)
      .order(recorded_at: :asc)
  end

  # Check if readings are anomalous (>2x standard deviation from mean)
  def anomalous_readings(hours = 24)
    readings = environmental_readings
      .where("recorded_at > ?", hours.hours.ago)
      .pluck(:value)

    return [] if readings.empty?

    mean = readings.sum.to_f / readings.length
    variance = readings.map { |r| (r - mean)**2 }.sum / readings.length
    std_dev = Math.sqrt(variance)

    environmental_readings
      .where("recorded_at > ?", hours.hours.ago)
      .where("value > ? OR value < ?", mean + (2 * std_dev), mean - (2 * std_dev))
  end

  # Check if sensor has geometry data
  def has_geom?
    respond_to?(:geom) && geom.present?
  end

  # Calculate distance to another sensor in kilometers
  def distance_to(other_sensor)
    return nil unless has_geom? && other_sensor.has_geom?

    if self.class.connection.adapter_name.downcase.include?("postgis")
      result = self.class.connection.execute(
        "SELECT ST_Distance(
          '#{geom.as_text}'::geography,
          '#{other_sensor.geom.as_text}'::geography
        ) as distance"
      ).first
      (result["distance"].to_f / 1000.0).round(2)
    else
      haversine_distance(other_sensor)
    end
  end

  # Update PostGIS geometry field from latitude/longitude coordinates
  # Called from controllers and jobs when importing/updating sensors
  def update_geom_from_coordinates
    if latitude.present? && longitude.present?
      self.geom = "POINT(#{longitude} #{latitude})"
    end
  end

  private

  def coordinates_changed?
    latitude_changed? || longitude_changed?
  end

  def coordinates_must_be_present_or_location_exists
    return if location.present? # Location can provide coordinates
    return if latitude.present? && longitude.present?

    errors.add(:latitude, "can't be blank") if latitude.blank?
    errors.add(:longitude, "can't be blank") if longitude.blank?
  end

  def set_coordinates_from_location_if_blank
    return unless location.present?
    return if latitude.present? && longitude.present?

    self.latitude = location.latitude if latitude.blank?
    self.longitude = location.longitude if longitude.blank?
  end

  # Haversine formula for distance calculation (fallback)
  def haversine_distance(other_sensor)
    earth_radius_km = 6371.0

    lat1_rad = latitude * Math::PI / 180
    lat2_rad = other_sensor.latitude * Math::PI / 180
    delta_lat = (other_sensor.latitude - latitude) * Math::PI / 180
    delta_lng = (other_sensor.longitude - longitude) * Math::PI / 180

    a = Math.sin(delta_lat / 2)**2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(delta_lng / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    (earth_radius_km * c).round(2)
  end
end
