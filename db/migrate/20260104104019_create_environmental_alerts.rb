# frozen_string_literal: true

class CreateEnvironmentalAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :environmental_alerts do |t|
      # Associations
      t.references :environmental_reading, foreign_key: true, null: true, index: true
      t.references :environmental_sensor, null: false, foreign_key: true, index: true

      # Alert details
      t.string :alert_type, null: false
      t.string :severity, null: false
      t.text :message, null: false
      t.datetime :resolved_at

      # Metadata for additional alert information
      t.jsonb :metadata, default: {}

      # Timestamps
      t.timestamps
    end

    # Indexes for common query patterns
    add_index :environmental_alerts, :alert_type
    add_index :environmental_alerts, :severity
    add_index :environmental_alerts, :resolved_at
    add_index :environmental_alerts, :created_at

    # Composite indexes for filtering active/critical alerts
    add_index :environmental_alerts,
              [ :severity, :resolved_at ],
              name: "index_alerts_severity_resolved"

    add_index :environmental_alerts,
              [ :environmental_sensor_id, :created_at ],
              name: "index_alerts_sensor_created"

    add_index :environmental_alerts,
              [ :environmental_sensor_id, :resolved_at ],
              name: "index_alerts_sensor_resolved"

    # Partial index for active alerts only (most frequently queried)
    add_index :environmental_alerts,
              [ :severity, :created_at ],
              where: "resolved_at IS NULL",
              name: "index_alerts_active_by_severity"

    # Partial index for critical active alerts
    add_index :environmental_alerts,
              :created_at,
              where: "severity = 'critical' AND resolved_at IS NULL",
              name: "index_alerts_critical_active"
  end
end
