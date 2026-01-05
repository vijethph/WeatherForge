# frozen_string_literal: true

class AddGeomToLocations < ActiveRecord::Migration[8.1]
  def up
    # Add PostGIS geometry column to locations table
    # SRID 4326 = WGS84 (standard for GPS coordinates)
    add_column :locations, :geom, :geometry, geographic: true, srid: 4326

    # Migrate existing latitude/longitude data to geometry column
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE locations
          SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
          WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
        SQL
      end
    end

    # Add spatial index using GIST (Generalized Search Tree) for efficient spatial queries
    add_index :locations, :geom, using: :gist, name: "index_locations_on_geom"

    Rails.logger.info "Successfully added geometry column and spatial index to locations table"
  end

  def down
    # Remove spatial index first
    remove_index :locations, name: "index_locations_on_geom"

    # Remove geometry column
    remove_column :locations, :geom
  end
end
