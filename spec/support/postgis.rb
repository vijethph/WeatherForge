# frozen_string_literal: true

# PostGIS configuration for RSpec tests
# Ensures geometry columns are properly initialized and type system is registered

RSpec.configure do |config|
  config.before(:suite) do
    # Register PostGIS types with ActiveRecord to suppress OID warnings
    # This resolves: "unknown OID 18054: failed to recognize type of 'geom'"
    ActiveRecord::Base.connection.execute("SELECT NULL::geometry") rescue nil

    # Initialize RGeo factory for PostGIS adapter
    # This ensures geometry columns are properly recognized
    RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
      config.default = RGeo::Geographic.spherical_factory(srid: 4326)
    end

    # Load PostGIS extension if not already loaded
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS postgis")
  end
end
