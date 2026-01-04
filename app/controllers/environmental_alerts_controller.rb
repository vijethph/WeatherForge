# frozen_string_literal: true

# Controller for environmental alerts
# Handles alert management, resolution, and filtering
class EnvironmentalAlertsController < ApplicationController
  before_action :set_alert, only: [ :show, :update, :destroy, :resolve, :dismiss ]

  # GET /environmental_alerts
  # List all alerts with filtering
  def index
    @alerts = EnvironmentalAlert.includes(:environmental_sensor, :environmental_reading)
                                .order(created_at: :desc)

    # Apply filters
    @alerts = apply_filters(@alerts)

    # Pagination
    @alerts = @alerts.page(params[:page]).per(25)

    # Statistics
    @stats = {
      total: @alerts.count,
      active: EnvironmentalAlert.active.count,
      resolved: EnvironmentalAlert.resolved.count,
      by_severity: EnvironmentalAlert.group(:severity).count
    }

    respond_to do |format|
      format.html
      format.json do
        render json: @alerts.as_json(
          include: {
            environmental_sensor: { only: [ :id, :name, :sensor_type, :latitude, :longitude, :location_id ] }
          }
        )
      end
    end
  end

  # GET /environmental_alerts/:id
  # Show alert details
  def show
    respond_to do |format|
      format.html
      format.json do
        render json: @alert.as_json(
          include: {
            environmental_sensor: { only: [ :id, :name, :sensor_type, :latitude, :longitude ] },
            environmental_reading: { only: [ :id, :value, :parameter_name, :unit, :recorded_at ] }
          }
        )
      end
    end
  end

  # POST /environmental_alerts
  # Create new alert
  def create
    @alert = EnvironmentalAlert.new(alert_params)

    if @alert.save
      respond_to do |format|
        format.html { redirect_to @alert, notice: "Alert created successfully" }
        format.json { render json: @alert, status: :created }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Failed to create alert: #{@alert.errors.full_messages.join(', ')}"
          redirect_to environmental_alerts_path, status: :unprocessable_entity
        end
        format.json { render json: @alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /environmental_alerts/:id
  # Update alert
  def update
    if @alert.update(alert_params)
      respond_to do |format|
        format.html { redirect_to @alert, notice: "Alert updated successfully" }
        format.json { render json: @alert, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /environmental_alerts/:id
  # Destroy alert
  def destroy
    @alert.destroy!

    respond_to do |format|
      format.html { redirect_to environmental_alerts_path, notice: "Alert deleted successfully" }
      format.json { head :no_content }
    end
  end

  # POST /environmental_alerts/:id/resolve
  # Mark alert as resolved
  def resolve
    resolution_note = params[:resolution_note] || "Resolved manually"

    if @alert.resolve!(resolution_note: resolution_note)
      respond_to do |format|
        format.html { redirect_to @alert, notice: "Alert resolved successfully" }
        format.json { render json: @alert, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to @alert, alert: "Failed to resolve alert" }
        format.json { render json: @alert.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /environmental_alerts/:id/dismiss
  # Dismiss alert without resolution
  def dismiss
    @alert.update(
      resolved_at: Time.current,
      resolution_notes: "Dismissed by user"
    )

    respond_to do |format|
      format.html { redirect_to environmental_alerts_path, notice: "Alert dismissed" }
      format.json { render json: @alert, status: :ok }
    end
  end

  # POST /environmental_alerts/resolve_all
  # Bulk resolve alerts
  def resolve_all
    alert_ids = params[:alert_ids]

    if alert_ids.present?
      alerts = EnvironmentalAlert.where(id: alert_ids, resolved_at: nil)
      resolved_count = 0

      alerts.each do |alert|
        if alert.resolve!("Bulk resolved")
          resolved_count += 1
        end
      end

      respond_to do |format|
        format.html { redirect_to environmental_alerts_path, notice: "Resolved #{resolved_count} alerts" }
        format.json { render json: { resolved_count: resolved_count }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to environmental_alerts_path, alert: "No alerts selected" }
        format.json { render json: { error: "No alert IDs provided" }, status: :unprocessable_entity }
      end
    end
  end

  # GET /environmental_alerts/statistics
  # Alert statistics and trends
  def statistics
    time_range = params[:time_range]&.to_i || 7 # days

    stats = {
      total: EnvironmentalAlert.count,
      active: EnvironmentalAlert.active.count,
      resolved: EnvironmentalAlert.resolved.count,
      by_severity: EnvironmentalAlert.group(:severity).count,
      by_type: EnvironmentalAlert.group(:alert_type).count,
      recent_24h: EnvironmentalAlert.where("created_at >= ?", 24.hours.ago).count,
      recent_7d: EnvironmentalAlert.where("created_at >= ?", 7.days.ago).count,
      top_sensors: top_sensors_with_alerts(5),
      trend: alert_trend(time_range)
    }

    respond_to do |format|
      format.json { render json: stats }
    end
  end

  # GET /environmental_alerts/summary
  # Alert summary statistics
  def summary
    stats = {
      total: EnvironmentalAlert.count,
      active: EnvironmentalAlert.active.count,
      resolved: EnvironmentalAlert.resolved.count,
      by_severity: EnvironmentalAlert.group(:severity).count,
      by_type: EnvironmentalAlert.group(:alert_type).count
    }

    respond_to do |format|
      format.json { render json: stats }
    end
  end

  # GET /environmental_alerts/timeline
  # Timeline of alerts grouped by time period
  def timeline
    group_by = params[:group_by] || "day"
    days = params[:days]&.to_i || 7

    timeline_data = []

    case group_by
    when "hour"
      (0..24).each do |i|
        time = i.hours.ago
        count = EnvironmentalAlert.where(
          created_at: time.beginning_of_hour..time.end_of_hour
        ).count

        timeline_data << {
          time: time.beginning_of_hour.iso8601,
          count: count
        }
      end
    when "day"
      days.times do |i|
        date = i.days.ago.to_date
        count = EnvironmentalAlert.where(
          created_at: date.beginning_of_day..date.end_of_day
        ).count

        timeline_data << {
          time: date.iso8601,
          count: count
        }
      end
    end

    respond_to do |format|
      format.json { render json: timeline_data.reverse }
    end
  end

  private

  def set_alert
    @alert = EnvironmentalAlert.find(params[:id])
  end

  def alert_params
    params.require(:environmental_alert).permit(
      :environmental_sensor_id,
      :environmental_reading_id,
      :alert_type,
      :severity,
      :message,
      metadata: {}
    )
  end

  def apply_filters(alerts)
    # Filter by status
    case params[:status]
    when "active"
      alerts = alerts.active
    when "resolved"
      alerts = alerts.resolved
    end

    # Filter by severity
    alerts = alerts.where(severity: params[:severity]) if params[:severity].present?

    # Filter by alert type
    alerts = alerts.where(alert_type: params[:alert_type]) if params[:alert_type].present?

    # Filter by sensor
    alerts = alerts.where(environmental_sensor_id: params[:sensor_id]) if params[:sensor_id].present?

    # Filter by location
    if params[:location_id].present?
      alerts = alerts.joins(:environmental_sensor)
                    .where(environmental_sensors: { location_id: params[:location_id] })
    end

    # Filter by time range
    if params[:created_after].present?
      created_after = Time.zone.parse(params[:created_after])
      alerts = alerts.where("created_at >= ?", created_after)
    end

    alerts
  end

  def top_sensors_with_alerts(limit = 5)
    EnvironmentalAlert.joins(:environmental_sensor)
                     .where("created_at >= ?", 7.days.ago)
                     .group("environmental_sensors.id", "environmental_sensors.name")
                     .select("environmental_sensors.id, environmental_sensors.name, COUNT(*) as alert_count")
                     .order("alert_count DESC")
                     .limit(limit)
                     .map { |result| { sensor_id: result.id, sensor_name: result.name, alert_count: result.alert_count } }
  end

  def alert_trend(days)
    trend_data = []

    days.times do |i|
      date = i.days.ago.to_date
      count = EnvironmentalAlert.where(
        created_at: date.beginning_of_day..date.end_of_day
      ).count

      trend_data << {
        date: date.iso8601,
        count: count
      }
    end

    trend_data.reverse
  end
end
