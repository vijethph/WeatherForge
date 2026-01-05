# frozen_string_literal: true

# Background job to sync environmental sensors from OpenAQ API
# Discovers sensors near existing locations and creates/updates sensor records
class SyncEnvironmentalSensorsJob < ApplicationJob
  queue_as :default

  # Default search radius in kilometers
  DEFAULT_RADIUS_KM = 50

  # Parameters to prioritize when importing sensors
  PRIORITY_PARAMETERS = %w[pm25 pm10 o3 no2 so2 co].freeze

  def perform(location_id: nil, radius_km: DEFAULT_RADIUS_KM)
    if location_id.present?
      sync_sensors_for_location(location_id, radius_km)
    else
      sync_sensors_for_all_locations(radius_km)
    end
  rescue StandardError => e
    Rails.logger.error "SyncEnvironmentalSensorsJob failed: #{e.message}\n#{e.backtrace.join("\n")}"
    raise
  end

  private

  def sync_sensors_for_all_locations(radius_km)
    Rails.logger.info "Starting environmental sensors sync for all locations (radius: #{radius_km}km)"

    total_synced = 0
    total_created = 0
    total_updated = 0

    Location.find_each do |location|
      stats = sync_sensors_for_location(location.id, radius_km)
      total_synced += stats[:synced]
      total_created += stats[:created]
      total_updated += stats[:updated]
    rescue StandardError => e
      Rails.logger.error "Failed to sync sensors for location #{location.name}: #{e.message}"
    end

    Rails.logger.info "Environmental sensors sync completed: #{total_synced} synced (#{total_created} created, #{total_updated} updated)"

    broadcast_sensors_update

    { synced: total_synced, created: total_created, updated: total_updated }
  end

  def sync_sensors_for_location(location_id, radius_km)
    location = Location.find(location_id)
    service = OpenAqService.new

    Rails.logger.info "Syncing sensors near #{location.name} (#{radius_km}km radius)"

    # Fetch sensors from OpenAQ API
    sensors_data = service.fetch_sensors_near_location(
      lat: location.latitude,
      lon: location.longitude,
      radius: radius_km,
      limit: 100
    )

    return { synced: 0, created: 0, updated: 0 } if sensors_data.blank?

    synced_count = 0
    created_count = 0
    updated_count = 0

    sensors_data.each do |sensor_data|
      # Skip sensors without priority parameters
      next unless has_priority_parameters?(sensor_data[:parameters])

      sensor = find_or_initialize_sensor(sensor_data, location)

      if sensor.new_record?
        create_sensor(sensor, sensor_data, location)
        created_count += 1
      else
        update_sensor(sensor, sensor_data)
        updated_count += 1
      end

      synced_count += 1

      # Broadcast individual sensor update
      broadcast_sensor_update(sensor)
    rescue StandardError => e
      Rails.logger.error "Failed to sync sensor #{sensor_data[:name]}: #{e.message}"
    end

    Rails.logger.info "Synced #{synced_count} sensors for #{location.name} (#{created_count} new, #{updated_count} updated)"

    { synced: synced_count, created: created_count, updated: updated_count }
  end

  def find_or_initialize_sensor(sensor_data, location)
    # Try to find existing sensor by OpenAQ ID
    openaq_id = sensor_data[:openaq_id]

    if openaq_id.present?
      sensor = EnvironmentalSensor.find_by("metadata->>'openaq_id' = ?", openaq_id.to_s)
      return sensor if sensor.present?
    end

    # If not found, initialize new sensor
    EnvironmentalSensor.new
  end

  def create_sensor(sensor, sensor_data, location)
    # Use first_updated as installation_date, fallback to current time
    installation_date = sensor_data[:first_updated] || Time.current

    sensor.assign_attributes(
      name: sensor_data[:name],
      sensor_type: determine_sensor_type(sensor_data[:parameters]),
      manufacturer: sensor_data[:manufacturer] || "Unknown",
      installation_date: installation_date,
      latitude: sensor_data[:latitude],
      longitude: sensor_data[:longitude],
      status: sensor_data[:is_monitor] ? :active : :inactive,
      location: location,
      metadata: build_sensor_metadata(sensor_data)
    )

    sensor.save!
    sensor.update_geom_from_coordinates

    # Fetch and store individual sensor IDs from OpenAQ
    fetch_and_store_sensor_ids(sensor, sensor_data[:openaq_id])

    Rails.logger.info "Created sensor: #{sensor.name} (ID: #{sensor.id}, OpenAQ: #{sensor_data[:openaq_id]})"
  end

  def update_sensor(sensor, sensor_data)
    # Update metadata and status
    updated_metadata = sensor.metadata.merge(
      last_synced_at: Time.current.iso8601,
      parameters: sensor_data[:parameters],
      distance: sensor_data[:distance],
      last_updated: sensor_data[:last_updated]&.iso8601
    )

    sensor.update!(
      status: sensor_data[:is_monitor] ? :active : :inactive,
      metadata: updated_metadata
    )

    # Fetch and store individual sensor IDs if not already present
    if sensor.metadata["openaq_sensor_ids"].blank?
      fetch_and_store_sensor_ids(sensor, sensor_data[:openaq_id])
    end

    Rails.logger.info "Updated sensor: #{sensor.name} (ID: #{sensor.id})"
  end

  def build_sensor_metadata(sensor_data)
    {
      openaq_id: sensor_data[:openaq_id],
      locality: sensor_data[:locality],
      country: sensor_data[:country],
      country_code: sensor_data[:country_code],
      parameters: sensor_data[:parameters],
      is_mobile: sensor_data[:is_mobile],
      is_monitor: sensor_data[:is_monitor],
      distance: sensor_data[:distance],
      timezone: sensor_data[:timezone],
      instruments: sensor_data[:instruments],
      first_updated: sensor_data[:first_updated]&.iso8601,
      last_updated: sensor_data[:last_updated]&.iso8601,
      last_synced_at: Time.current.iso8601
    }
  end

  def determine_sensor_type(parameters)
    return :air_quality if (parameters & PRIORITY_PARAMETERS).any?
    return :temperature if parameters.include?("temperature")
    return :humidity if parameters.include?("humidity")

    :air_quality # default
  end

  def has_priority_parameters?(parameters)
    (parameters & PRIORITY_PARAMETERS).any?
  end

  def fetch_and_store_sensor_ids(sensor, location_id)
    # Fetch location metadata to get individual sensor IDs
    service = OpenAqService.new
    metadata = service.fetch_latest_measurements(location_id: location_id)

    return unless metadata && metadata[:sensors]&.any?

    # Store sensor IDs with their parameters (use :parameter key, not :parameter_name)
    sensor_ids = metadata[:sensors].map do |s|
      {
        sensor_id: s[:sensor_id],
        parameter: s[:parameter], # This is the correct key
        unit: s[:units]
      }
    end.compact

    # Update metadata with sensor IDs
    sensor.update(
      metadata: sensor.metadata.merge(
        openaq_sensor_ids: sensor_ids,
        sensor_ids_updated_at: Time.current.iso8601
      )
    )

    Rails.logger.info "Stored #{sensor_ids.length} sensor IDs for #{sensor.name}"
  rescue StandardError => e
    Rails.logger.error "Failed to fetch sensor IDs for #{sensor.name}: #{e.message}"
  end

  def broadcast_sensor_update(sensor)
    # Broadcast to sensor-specific channel
    Turbo::StreamsChannel.broadcast_update_to(
      "sensor_#{sensor.id}",
      target: "sensor_card_#{sensor.id}",
      partial: "environmental_sensors/sensor_card",
      locals: { sensor: sensor }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast sensor update: #{e.message}"
  end

  def broadcast_sensors_update
    # Broadcast to general sensors channel
    Turbo::StreamsChannel.broadcast_update_to(
      "environmental_sensors",
      target: "sensors_list",
      partial: "environmental_sensors/sensors_list",
      locals: { sensors: EnvironmentalSensor.active.includes(:location).limit(50) }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast sensors update: #{e.message}"
  end
end
