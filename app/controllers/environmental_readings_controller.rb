# frozen_string_literal: true

# Controller for environmental sensor readings
# Handles viewing time-series data and charts
class EnvironmentalReadingsController < ApplicationController
  before_action :set_sensor, only: [ :index, :create ]
  before_action :set_reading, only: [ :show, :destroy ]

  # GET /environmental_sensors/:sensor_id/readings
  # List readings for a specific sensor
  def index
    unless @sensor
      redirect_to environmental_sensors_path, alert: "Sensor not found"
      return
    end

    @readings = @sensor.environmental_readings
                      .order(recorded_at: :desc)

    # Apply time range filter
    @readings = apply_time_filter(@readings)

    # Apply parameter filter
    @readings = @readings.where(parameter_name: params[:parameter]) if params[:parameter].present?

    # Pagination
    @readings = @readings.page(params[:page]).per(50)

    # Chart data for visualizations
    @chart_data = prepare_chart_data(@sensor, params[:parameter])

    respond_to do |format|
      format.html
      format.json { render json: @readings }
    end
  end

  # GET /environmental_readings/:id
  # Show single reading details
  def show
    respond_to do |format|
      format.html
      format.json do
        render json: @reading.as_json(
          include: {
            environmental_sensor: { only: [ :id, :name, :sensor_type ] },
            environmental_alert: { only: [ :id, :alert_type, :severity ] }
          },
          methods: [ :health_level ]
        )
      end
    end
  end

  # POST /environmental_sensors/:sensor_id/readings
  # Create new reading for a sensor
  def create
    unless @sensor
      respond_to do |format|
        format.html { redirect_to environmental_sensors_path, alert: "Sensor not found" }
        format.json { render json: { error: "Sensor not found" }, status: :not_found }
      end
      return
    end

    @reading = @sensor.environmental_readings.new(reading_params)

    if @reading.save
      respond_to do |format|
        format.html { redirect_to environmental_sensor_readings_path(@sensor), notice: "Reading created successfully" }
        format.json { render json: @reading, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @reading.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /environmental_sensors/:sensor_id/readings/:id
  # Destroy reading
  def destroy
    @reading.destroy!

    respond_to do |format|
      format.html { redirect_to environmental_sensor_readings_path(@reading.environmental_sensor), notice: "Reading deleted successfully" }
      format.json { head :no_content }
    end
  end

  # GET /environmental_readings/latest
  # Get latest readings across all sensors
  def latest
    @latest_readings = EnvironmentalReading
      .select("DISTINCT ON (environmental_sensor_id, parameter_name) *")
      .order("environmental_sensor_id, parameter_name, recorded_at DESC")
      .includes(:environmental_sensor)
      .limit(100)

    respond_to do |format|
      format.html
      format.json { render json: @latest_readings }
    end
  end

  # GET /environmental_readings/statistics
  # Aggregate statistics for readings
  def statistics
    stats = {}

    if params[:sensor_id].present?
      sensor = EnvironmentalSensor.find(params[:sensor_id])
      stats = calculate_sensor_statistics(sensor, params[:parameter])
    elsif params[:parameter].present?
      stats = calculate_parameter_statistics(params[:parameter])
    else
      stats = calculate_global_statistics
    end

    respond_to do |format|
      format.json { render json: stats }
    end
  end

  private

  def set_sensor
    if params[:sensor_id].present?
      @sensor = EnvironmentalSensor.find_by(id: params[:sensor_id])
    end
  end

  def set_reading
    @reading = EnvironmentalReading.find(params[:id])
  end

  def reading_params
    params.require(:environmental_reading).permit(
      :parameter_name,
      :value,
      :unit,
      :recorded_at
    )
  end

  def apply_time_filter(readings)
    if params[:start_date].present? && params[:end_date].present?
      start_time = Time.zone.parse(params[:start_date])
      end_time = Time.zone.parse(params[:end_date])
      readings = readings.where(recorded_at: start_time..end_time)
    elsif params[:time_range].present?
      case params[:time_range]
      when "1h"
        readings = readings.where("recorded_at >= ?", 1.hour.ago)
      when "6h"
        readings = readings.where("recorded_at >= ?", 6.hours.ago)
      when "24h"
        readings = readings.where("recorded_at >= ?", 24.hours.ago)
      when "7d"
        readings = readings.where("recorded_at >= ?", 7.days.ago)
      when "30d"
        readings = readings.where("recorded_at >= ?", 30.days.ago)
      end
    else
      # Default to last 24 hours
      readings = readings.where("recorded_at >= ?", 24.hours.ago)
    end

    readings
  end

  def prepare_chart_data(sensor, parameter_name = nil)
    readings = sensor.environmental_readings
                    .where("recorded_at >= ?", 24.hours.ago)
                    .order(recorded_at: :asc)

    readings = readings.where(parameter_name: parameter_name) if parameter_name.present?

    # Group by parameter if not filtered
    if parameter_name.present?
      {
        parameter_name => readings.map { |r| [ r.recorded_at.to_i * 1000, r.value ] }
      }
    else
      readings.group_by(&:parameter_name).transform_values do |param_readings|
        param_readings.map { |r| [ r.recorded_at.to_i * 1000, r.value ] }
      end
    end
  end

  def calculate_sensor_statistics(sensor, parameter_name = nil)
    readings = sensor.environmental_readings
                    .where("recorded_at >= ?", 24.hours.ago)

    readings = readings.where(parameter_name: parameter_name) if parameter_name.present?

    {
      sensor_id: sensor.id,
      sensor_name: sensor.name,
      parameter: parameter_name,
      count: readings.count,
      average: readings.average(:value)&.round(2),
      minimum: readings.minimum(:value)&.round(2),
      maximum: readings.maximum(:value)&.round(2),
      latest: readings.order(recorded_at: :desc).first&.value&.round(2),
      time_range: "24h"
    }
  end

  def calculate_parameter_statistics(parameter_name)
    readings = EnvironmentalReading
      .where(parameter_name: parameter_name)
      .where("recorded_at >= ?", 24.hours.ago)

    {
      parameter: parameter_name,
      total_sensors: readings.select(:environmental_sensor_id).distinct.count,
      count: readings.count,
      average: readings.average(:value)&.round(2),
      minimum: readings.minimum(:value)&.round(2),
      maximum: readings.maximum(:value)&.round(2),
      time_range: "24h"
    }
  end

  def calculate_global_statistics
    {
      total_sensors: EnvironmentalSensor.count,
      active_sensors: EnvironmentalSensor.active.count,
      total_readings_24h: EnvironmentalReading.where("recorded_at >= ?", 24.hours.ago).count,
      total_alerts_active: EnvironmentalAlert.active.count,
      parameters: EnvironmentalReading.distinct.pluck(:parameter_name).sort
    }
  end
end
