# frozen_string_literal: true

class CreateEnvironmentalReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :environmental_readings do |t|
      # Associations
      t.references :environmental_sensor, null: false, foreign_key: true, index: true

      # Reading data
      t.float :value, null: false
      t.string :unit, null: false
      t.datetime :recorded_at, null: false

      # Store original API response for debugging/auditing
      t.jsonb :raw_data, default: {}

      # Timestamps
      t.timestamps
    end

    # Indexes for performance optimization
    add_index :environmental_readings, :recorded_at
    add_index :environmental_readings, :value

    # Unique constraint to prevent duplicate readings at same timestamp
    add_index :environmental_readings,
              [ :environmental_sensor_id, :recorded_at ],
              unique: true,
              name: "index_readings_sensor_recorded_unique"

    # Composite index for time-range queries (most common pattern)
    add_index :environmental_readings,
              [ :environmental_sensor_id, :recorded_at ],
              name: "index_readings_sensor_time_range"

    # Composite index for threshold queries (filtering by value)
    add_index :environmental_readings,
              [ :environmental_sensor_id, :value ],
              name: "index_readings_sensor_value"

    # Note: Partial index with NOW() cannot be used as NOW() is not immutable
    # Instead, we'll rely on regular indexes and application-level filtering for recent data
  end
end
