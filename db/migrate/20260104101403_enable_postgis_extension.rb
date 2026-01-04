# frozen_string_literal: true

class EnablePostgisExtension < ActiveRecord::Migration[8.1]
  def up
    # Enable PostGIS extension for spatial features
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    # Enable PostGIS topology support (optional but recommended)
    execute "CREATE EXTENSION IF NOT EXISTS postgis_topology"

    # Verify PostGIS installation
    Rails.logger.info "PostGIS Version: #{connection.execute('SELECT PostGIS_Version()').first['postgis_version']}"
  end

  def down
    # WARNING: This will remove all spatial data and functions
    # Only run this if you're sure you want to completely remove PostGIS
    execute "DROP EXTENSION IF EXISTS postgis_topology CASCADE"
    execute "DROP EXTENSION IF EXISTS postgis CASCADE"
  end
end
