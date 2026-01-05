# frozen_string_literal: true

class CreateEnvironmentalSensors < ActiveRecord::Migration[8.1]
  def change
    create_table :environmental_sensors do |t|
      # Associations
      t.references :location, foreign_key: true, null: true, index: true

      # Core attributes
      t.string :name, null: false
      t.string :sensor_type, null: false, default: "air_quality"
      t.string :manufacturer, null: false
      t.date :installation_date, null: false
      t.date :last_maintenance
      t.string :status, default: "active", null: false

      # Geographic coordinates (for fallback if PostGIS not available)
      t.float :latitude, null: false
      t.float :longitude, null: false

      # PostGIS spatial column (SRID 4326 = WGS84)
      t.geometry :geom, geographic: true, srid: 4326

      # Metadata storage for additional sensor info
      t.jsonb :metadata, default: {}

      # Timestamps
      t.timestamps
    end

    # Standard indexes for common queries
    add_index :environmental_sensors, :name
    add_index :environmental_sensors, :sensor_type
    add_index :environmental_sensors, :status
    add_index :environmental_sensors, :latitude
    add_index :environmental_sensors, :longitude
    add_index :environmental_sensors, :installation_date

    # Spatial index (GIST) for geographic queries - critical for performance
    add_index :environmental_sensors, :geom, using: :gist, name: "index_environmental_sensors_on_geom"

    # Composite index for common query patterns
    add_index :environmental_sensors, [ :sensor_type, :status ], name: "index_sensors_on_type_and_status"
    add_index :environmental_sensors, [ :location_id, :status ], name: "index_sensors_on_location_and_status"

    # Populate geometry from coordinates for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE environmental_sensors
          SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
          WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
        SQL
      end
    end
  end
end
