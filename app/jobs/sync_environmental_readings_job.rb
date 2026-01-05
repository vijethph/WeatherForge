# frozen_string_literal: true

# Background job to sync environmental readings from OpenAQ API
# Fetches latest measurements for all active sensors and creates reading records
class SyncEnvironmentalReadingsJob < ApplicationJob
  queue_as :default

  # Time range for fetching measurements (7 days to capture recent data)
  FETCH_TIME_RANGE_HOURS = 168 # 7 days

  # Maximum number of sensors to sync per job run
  MAX_SENSORS_PER_RUN = 100

  def perform(sensor_id: nil)
    if sensor_id.present?
      sync_readings_for_sensor(sensor_id)
    else
      sync_readings_for_all_sensors
    end
  rescue StandardError => e
    Rails.logger.error "SyncEnvironmentalReadingsJob failed: #{e.message}\n#{e.backtrace.join("\n")}"
    raise
  end

  private

  def sync_readings_for_all_sensors
    Rails.logger.info "Starting environmental readings sync for all active sensors"

    total_sensors = 0
    total_readings = 0

    # Only sync active sensors with OpenAQ metadata
    sensors = EnvironmentalSensor.active
                                 .where("metadata->>'openaq_id' IS NOT NULL")
                                 .limit(MAX_SENSORS_PER_RUN)

    sensors.find_each do |sensor|
      readings_count = sync_readings_for_sensor(sensor.id)
      total_sensors += 1
      total_readings += readings_count
    rescue StandardError => e
      Rails.logger.error "Failed to sync readings for sensor #{sensor.name}: #{e.message}"
    end

    Rails.logger.info "Environmental readings sync completed: #{total_readings} readings for #{total_sensors} sensors"

    broadcast_readings_update

    { sensors: total_sensors, readings: total_readings }
  end

  def sync_readings_for_sensor(sensor_id)
    sensor = EnvironmentalSensor.find(sensor_id)
    service = OpenAqService.new

    sensor_ids = sensor.metadata["openaq_sensor_ids"]

    unless sensor_ids.present? && sensor_ids.is_a?(Array)
      Rails.logger.warn "Sensor #{sensor.name} has no OpenAQ sensor IDs, skipping"
      return 0
    end

    Rails.logger.info "Syncing readings for sensor: #{sensor.name} (#{sensor_ids.length} sensors)"

    readings_created = 0

    # Fetch measurements for each OpenAQ sensor ID
    sensor_ids.each do |sensor_info|
      openaq_sensor_id = sensor_info["sensor_id"]
      next unless openaq_sensor_id

      Rails.logger.info "Fetching measurements for sensor ID: #{openaq_sensor_id}"
      measurements = fetch_sensor_measurements(service, openaq_sensor_id)

      Rails.logger.info "Got #{measurements&.length || 0} measurements for sensor #{openaq_sensor_id}"
      next if measurements.blank?

      measurements.each do |measurement|
        Rails.logger.info "Creating reading: #{measurement[:parameter_name]} = #{measurement[:value]}"
        reading = create_reading(sensor, measurement)

        if reading.persisted?
          readings_created += 1
          # Broadcast individual reading update
          broadcast_reading_update(sensor, reading)
        else
          Rails.logger.warn "Reading not persisted: #{reading.errors.full_messages.join(", ")}"
        end
      rescue StandardError => e
        Rails.logger.error "Failed to process measurement: #{e.message}"
      end
    end

    # Update sensor's last sync timestamp
    sensor.update(metadata: sensor.metadata.merge(last_readings_sync: Time.current.iso8601))

    Rails.logger.info "Created #{readings_created} readings for sensor: #{sensor.name}"

    readings_created
  end

  def fetch_sensor_measurements(service, sensor_id)
    date_from = FETCH_TIME_RANGE_HOURS.hours.ago
    date_to = Time.current

    service.fetch_sensor_measurements(
      sensor_id: sensor_id,
      date_from: date_from,
      date_to: date_to,
      limit: 100
    )
  rescue StandardError => e
    Rails.logger.error "Failed to fetch measurements for sensor #{sensor_id}: #{e.message}"
    []
  end

  def create_reading(sensor, measurement)
    # Check if reading already exists (prevent duplicates)
    recorded_at = measurement[:recorded_at] || Time.current
    parameter = measurement[:parameter_name]

    existing = EnvironmentalReading.find_by(
      environmental_sensor: sensor,
      parameter_name: parameter,
      recorded_at: recorded_at
    )

    return existing if existing.present?

    # Create new reading
    reading = EnvironmentalReading.new(
      environmental_sensor: sensor,
      parameter_name: parameter,
      value: measurement[:value],
      unit: measurement[:units],
      recorded_at: recorded_at,
      raw_data: {
        period_label: measurement[:period_label],
        interval: measurement[:interval],
        has_flags: measurement[:has_flags]
      }
    )

    if reading.save
      Rails.logger.info "Created reading: #{parameter}=#{measurement[:value]} #{measurement[:units]} for #{sensor.name}"
    else
      Rails.logger.warn "Failed to save reading for #{sensor.name}: #{reading.errors.full_messages.join(", ")}"
    end

    reading
  end

  def broadcast_reading_update(sensor, reading)
    # Broadcast to sensor-specific readings channel
    Turbo::StreamsChannel.broadcast_append_to(
      "sensor_#{sensor.id}_readings",
      target: "readings_list_#{sensor.id}",
      partial: "environmental_readings/reading_row",
      locals: { reading: reading }
    )

    # Broadcast to sensor card to update latest value
    Turbo::StreamsChannel.broadcast_update_to(
      "sensor_#{sensor.id}",
      target: "sensor_latest_reading_#{sensor.id}",
      partial: "environmental_sensors/latest_reading",
      locals: { sensor: sensor, reading: reading }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast reading update: #{e.message}"
  end

  def broadcast_readings_update
    # Broadcast to general readings dashboard
    Turbo::StreamsChannel.broadcast_update_to(
      "environmental_readings",
      target: "latest_readings",
      partial: "environmental_readings/latest_readings_grid",
      locals: {
        readings: EnvironmentalReading
          .select("DISTINCT ON (environmental_sensor_id, parameter_name) *")
          .order("environmental_sensor_id, parameter_name, recorded_at DESC")
          .includes(:environmental_sensor)
          .limit(20)
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast readings update: #{e.message}"
  end
end
