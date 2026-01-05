ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Load PostGIS adapter early to enable geometry column type in schema.rb
require "active_record/connection_adapters/postgis_adapter" if defined?(ActiveRecord)
