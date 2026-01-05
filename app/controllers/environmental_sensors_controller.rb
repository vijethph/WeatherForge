# frozen_string_literal: true

# Controller for managing environmental sensors
# Handles CRUD operations, search, and integration with OpenAQ API
class EnvironmentalSensorsController < ApplicationController
  before_action :set_sensor, only: [ :show, :update, :destroy, :sync ]

  # GET /environmental_sensors
  # List all sensors with optional filtering
  def index
    @sensors = EnvironmentalSensor.includes(:location, :environmental_alerts)
                                  .order(created_at: :desc)

    # Apply filters if present
    @sensors = apply_filters(@sensors)

    # Pagination
    @sensors = @sensors.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json { render json: @sensors }
    end
  end

  # GET /environmental_sensors/search
  # Search for sensors by location coordinates
  def search
    # Show search form if no params provided
    if params[:latitude].blank? && params[:longitude].blank?
      @results = []
      respond_to do |format|
        format.html
        format.json { render json: { message: "Provide latitude and longitude to search" }, status: :ok }
      end
      return
    end

    if search_params_valid?
      service = OpenAqService.new
      @results = service.fetch_sensors_near_location(
        lat: params[:latitude].to_f,
        lon: params[:longitude].to_f,
        radius: params[:radius]&.to_i || 25,
        parameters: params[:parameters]&.split(","),
        limit: params[:limit]&.to_i || 50
      )

      respond_to do |format|
        format.html
        format.json { render json: @results }
      end
    else
      respond_to do |format|
        format.html { redirect_to environmental_sensors_path, alert: "Latitude and longitude are required" }
        format.json { render json: { error: "Invalid search parameters" }, status: :unprocessable_entity }
      end
    end
  end

  # GET /environmental_sensors/:id
  # Show sensor details with recent readings
  def show
    @readings = @sensor.environmental_readings
                       .order(recorded_at: :desc)
                       .limit(100)

    @recent_readings = @readings

    @active_alerts = @sensor.environmental_alerts
                            .active
                            .order(created_at: :desc)

    @latest_alert = @active_alerts.first

    # Chart data with dynamic time range (default: 24 hours)
    hours = params[:hours].to_i
    hours = 24 unless [ 24, 168, 720 ].include?(hours)
    @time_range_hours = hours

    @readings_24h = @sensor.environmental_readings
                           .where("recorded_at >= ?", hours.hours.ago)
                           .order(recorded_at: :asc)

    respond_to do |format|
      format.html
      format.json do
        render json: @sensor.as_json(
          include: {
            location: { only: [ :id, :name, :latitude, :longitude, :timezone, :country ] },
            recent_readings: { methods: :health_level },
            active_alerts: {}
          },
          methods: [ :distance_to ]
        )
      end
    end
  end

  # POST /environmental_sensors
  # Create new sensor (typically from OpenAQ import)
  def create
    @sensor = EnvironmentalSensor.new(sensor_params)

    if @sensor.save
      # Update geometry from coordinates if not present
      @sensor.update_geom_from_coordinates unless @sensor.geom.present?

      respond_to do |format|
        format.html { redirect_to @sensor, notice: "Sensor created successfully" }
        format.json { render json: @sensor, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sensor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /environmental_sensors/:id
  # Update sensor
  def update
    if @sensor.update(sensor_params)
      # Update geometry from coordinates if changed
      @sensor.update_geom_from_coordinates if @sensor.saved_change_to_latitude? || @sensor.saved_change_to_longitude?

      respond_to do |format|
        format.html { redirect_to @sensor, notice: "Sensor updated successfully" }
        format.json { render json: @sensor, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sensor.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /environmental_sensors/import_from_openaq
  # Import sensors from OpenAQ near a location
  def import_from_openaq
    if import_params_valid?
      service = OpenAqService.new
      sensors_data = service.fetch_sensors_near_location(
        lat: params[:latitude].to_f,
        lon: params[:longitude].to_f,
        radius: params[:radius]&.to_i || 25,
        limit: params[:limit]&.to_i || 50
      )

      imported_count = 0
      errors = []

      sensors_data.each do |sensor_data|
        sensor = import_sensor_from_openaq(sensor_data)
        if sensor.persisted?
          imported_count += 1
        else
          errors << { sensor: sensor_data[:name], errors: sensor.errors.full_messages }
        end
      end

      respond_to do |format|
        if errors.empty?
          format.html { redirect_to environmental_sensors_path, notice: "Successfully imported #{imported_count} sensors" }
          format.json { render json: { imported: imported_count }, status: :created }
        else
          format.html { redirect_to environmental_sensors_path, alert: "Imported #{imported_count} sensors with #{errors.count} errors" }
          format.json { render json: { imported: imported_count, errors: errors }, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to environmental_sensors_path, alert: "Latitude and longitude are required" }
        format.json { render json: { error: "Invalid import parameters" }, status: :unprocessable_entity }
      end
    end
  end

  # POST /environmental_sensors/:id/sync
  # Manually sync sensor data from OpenAQ
  def sync
    if @sensor.metadata["openaq_id"].present?
      service = OpenAqService.new
      location_data = service.fetch_latest_measurements(location_id: @sensor.metadata["openaq_id"])

      if location_data
        # Update sensor metadata
        @sensor.update(
          status: :active,
          last_reading_at: Time.current,
          metadata: @sensor.metadata.merge(
            sensors: location_data[:sensors],
            synced_at: Time.current.iso8601
          )
        )

        redirect_to @sensor, notice: "Sensor synced successfully"
      else
        redirect_to @sensor, alert: "Failed to sync sensor from OpenAQ"
      end
    else
      redirect_to @sensor, alert: "Sensor does not have OpenAQ ID"
    end
  end

  # DELETE /environmental_sensors/:id
  # Remove sensor and associated readings/alerts
  def destroy
    @sensor.destroy
    respond_to do |format|
      format.html { redirect_to environmental_sensors_path, notice: "Sensor removed successfully" }
      format.json { head :no_content }
    end
  end

  # GET /environmental_sensors/nearby
  # Find sensors near specified coordinates
  def nearby
    unless params[:latitude].present? && params[:longitude].present?
      respond_to do |format|
        format.html { redirect_to environmental_sensors_path, alert: "Latitude and longitude required" }
        format.json { render json: { error: "Latitude and longitude required" }, status: :bad_request }
      end
      return
    end

    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    radius_km = params[:radius]&.to_f || 10.0

    @sensors = EnvironmentalSensor.near_location(
      latitude: latitude,
      longitude: longitude,
      radius_km: radius_km
    )

    respond_to do |format|
      format.html
      format.json { render json: @sensors }
    end
  end

  # GET /environmental_sensors/map_data
  # GeoJSON data for map display
  def map_data
    @sensors = EnvironmentalSensor.includes(:location).all

    features = @sensors.map do |sensor|
      {
        type: "Feature",
        geometry: {
          type: "Point",
          coordinates: [ sensor.longitude, sensor.latitude ]
        },
        properties: {
          id: sensor.id,
          name: sensor.name,
          sensor_type: sensor.sensor_type,
          status: sensor.status,
          manufacturer: sensor.manufacturer,
          location_name: sensor.location&.name
        }
      }
    end

    geojson = {
      type: "FeatureCollection",
      features: features
    }

    respond_to do |format|
      format.json { render json: geojson }
    end
  end

  private

  def set_sensor
    @sensor = EnvironmentalSensor.find(params[:id])
  end

  def sensor_params
    params.require(:environmental_sensor).permit(
      :name, :sensor_type, :manufacturer, :model_number,
      :latitude, :longitude, :status, :location_id, :installation_date,
      metadata: {}
    )
  end

  def search_params_valid?
    params[:latitude].present? && params[:longitude].present?
  end

  def import_params_valid?
    params[:latitude].present? && params[:longitude].present?
  end

  def apply_filters(sensors)
    sensors = sensors.where(sensor_type: params[:sensor_type]) if params[:sensor_type].present?
    sensors = sensors.where(status: params[:status]) if params[:status].present?
    sensors = sensors.where(location_id: params[:location_id]) if params[:location_id].present?

    # Spatial filter: near coordinates
    if params[:near_lat].present? && params[:near_lon].present?
      radius = params[:near_radius]&.to_f || 50.0
      sensors = sensors.near_location(
        latitude: params[:near_lat].to_f,
        longitude: params[:near_lon].to_f,
        radius_km: radius
      )
    end

    sensors
  end

  def import_sensor_from_openaq(sensor_data)
    # Use JSONB query to find existing sensor by openaq_id
    sensor = EnvironmentalSensor.where("metadata @> ?", { openaq_id: sensor_data[:openaq_id] }.to_json).first
    sensor ||= EnvironmentalSensor.new

    sensor.assign_attributes(
      name: sensor_data[:name],
      sensor_type: :air_quality,
      latitude: sensor_data[:latitude],
      longitude: sensor_data[:longitude],
      manufacturer: sensor_data[:manufacturer] || "Unknown",
      installation_date: sensor_data[:first_updated] || Time.current,
      status: sensor_data[:is_monitor] ? :active : :inactive,
      metadata: {
        openaq_id: sensor_data[:openaq_id],
        locality: sensor_data[:locality],
        country: sensor_data[:country],
        country_code: sensor_data[:country_code],
        timezone: sensor_data[:timezone],
        provider: sensor_data[:provider] || "Unknown",
        parameters: sensor_data[:parameters],
        is_mobile: sensor_data[:is_mobile],
        is_monitor: sensor_data[:is_monitor],
        instruments: sensor_data[:instruments],
        first_updated: sensor_data[:first_updated]&.iso8601,
        last_updated: sensor_data[:last_updated]&.iso8601,
        imported_at: Time.current.iso8601
      }
    )

    sensor.save
    sensor.update_geom_from_coordinates if sensor.persisted?
    sensor
  end
end
