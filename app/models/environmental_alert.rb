# frozen_string_literal: true

class EnvironmentalAlert < ApplicationRecord
  # Associations
  belongs_to :environmental_reading, optional: true
  belongs_to :environmental_sensor

  # Validations
  validates :alert_type, presence: true, inclusion: {
    in: %w[threshold_exceeded anomaly sensor_failure zone_alert network_issue],
    message: "must be a valid alert type"
  }
  validates :severity, presence: true, inclusion: {
    in: %w[low medium high critical],
    message: "must be a valid severity level"
  }
  validates :message, presence: true
  validates :environmental_sensor, presence: true

  # Scopes
  scope :active, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :critical, -> { where(severity: "critical") }
  scope :high, -> { where(severity: "high") }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :by_type, ->(type) { where(alert_type: type) }
  scope :created_after, ->(time) { where("created_at > ?", time) }

  # Callbacks
  after_create :broadcast_alert_to_subscribers
  after_update :broadcast_resolution, if: :saved_change_to_resolved_at?

  # Resolve alert
  def resolve!(resolution_note: nil)
    update(
      resolved_at: Time.current,
      metadata: metadata.merge(resolution_note: resolution_note).compact
    )
  end

  # Check if alert is resolved
  def resolved?
    resolved_at.present?
  end

  # Check if alert is active
  def active?
    resolved_at.nil?
  end

  # Severity color for UI badges
  def severity_color
    case severity
    when "critical" then "danger"
    when "high" then "warning"
    when "medium" then "info"
    when "low" then "secondary"
    else "secondary"
    end
  end

  # Alert type icon for UI
  def alert_type_icon
    case alert_type
    when "threshold_exceeded" then "⚠️"
    when "anomaly" then "📊"
    when "sensor_failure" then "🔧"
    when "zone_alert" then "📍"
    when "network_issue" then "🌐"
    else "ℹ️"
    end
  end

  # Human-readable alert type
  def alert_type_humanized
    alert_type.humanize.titleize
  end

  # Duration since alert was created (in human-readable format)
  def duration
    return nil if resolved_at.blank?

    seconds = (resolved_at - created_at).to_i
    if seconds < 60
      "#{seconds} seconds"
    elsif seconds < 3600
      "#{(seconds / 60).round} minutes"
    elsif seconds < 86400
      "#{(seconds / 3600).round} hours"
    else
      "#{(seconds / 86400).round} days"
    end
  end

  # Time since alert was created (for active alerts)
  def time_active
    return duration if resolved?

    seconds = (Time.current - created_at).to_i
    if seconds < 60
      "#{seconds}s"
    elsif seconds < 3600
      "#{(seconds / 60).round}m"
    elsif seconds < 86400
      "#{(seconds / 3600).round}h"
    else
      "#{(seconds / 86400).round}d"
    end
  end

  private

  def broadcast_alert_to_subscribers
    return unless severity.in?(%w[critical high])

    Rails.logger.info "Broadcasting alert #{id}: #{severity.upcase} - #{message}"

    # Broadcast to environmental alerts stream (for alerts page)
    Turbo::StreamsChannel.broadcast_append_to(
      "environmental_alerts",
      target: "alerts_list",
      partial: "environmental_alerts/alert",
      locals: { alert: self }
    )

    # Broadcast to sensor-specific stream (for sensor detail page)
    Turbo::StreamsChannel.broadcast_update_to(
      "sensor_#{environmental_sensor_id}_alerts",
      target: "sensor_#{environmental_sensor_id}_latest_alert",
      partial: "environmental_alerts/latest_alert_card",
      locals: { alert: self }
    )

    # Broadcast to dashboard stream (for main dashboard)
    Turbo::StreamsChannel.broadcast_update_to(
      "environmental_dashboard",
      target: "environmental_alerts_count",
      html: "<span class='badge bg-danger'>#{EnvironmentalAlert.active.count}</span>"
    )

    # Log critical alerts
    if severity == "critical"
      Rails.logger.warn "CRITICAL ALERT: #{message} (Sensor: #{environmental_sensor.name})"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast alert #{id}: #{e.message}\n#{e.backtrace.join("\n")}"
  end

  def broadcast_resolution
    Rails.logger.info "Broadcasting alert #{id} resolution after #{duration}"

    # Update alert status in alerts list
    Turbo::StreamsChannel.broadcast_replace_to(
      "environmental_alerts",
      target: "alert_#{id}",
      partial: "environmental_alerts/alert",
      locals: { alert: self }
    )

    # Update dashboard alert count
    Turbo::StreamsChannel.broadcast_update_to(
      "environmental_dashboard",
      target: "environmental_alerts_count",
      html: "<span class='badge bg-#{EnvironmentalAlert.active.count.zero? ? 'success' : 'danger'}'>#{EnvironmentalAlert.active.count}</span>"
    )
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast alert resolution #{id}: #{e.message}"
  end
end
