# frozen_string_literal: true

require "httparty"

# OpenAQ Air Quality Data Service
# Integrates with OpenAQ API v3 to fetch real-time air quality sensor data
# API Documentation: https://docs.openaq.org/
# Requires X-API-Key header for authentication
class OpenAqService
  include HTTParty

  base_uri ENV.fetch("OPENAQ_BASE_URL", "https://api.openaq.org/v3")

  # API rate limit: 300 requests per minute (default)
  RATE_LIMIT_PER_MINUTE = ENV.fetch("OPENAQ_RATE_LIMIT_PER_MINUTE", 300).to_i

  attr_reader :api_key

  def initialize
    @api_key = ENV["OPENAQ_API_KEY"]
    validate_configuration!
  end

  # Fetch sensors/instruments near a location
  # @param lat [Float] Latitude
  # @param lon [Float] Longitude
  # @param radius [Integer] Radius in kilometers (default: 25km, max: 25km per OpenAQ API limit)
  # @param parameters [Array<String>] Filter by parameters (e.g., ['pm25', 'pm10', 'o3'])
  # @param limit [Integer] Maximum results (default: 100, max: 1000)
  # @return [Array<Hash>] Array of sensor hashes
  def fetch_sensors_near_location(lat:, lon:, radius: 25, parameters: nil, limit: 100)
    endpoint = "/locations"

    # OpenAQ API has max radius of 25km (25000 meters)
    radius_km = [ radius, 25 ].min
    query_params = {
      coordinates: "#{lat},#{lon}",
      radius: radius_km * 1000, # Convert km to meters
      limit: [ limit, 1000 ].min
    }

    query_params[:parameters] = parameters.join(",") if parameters.present?

    Rails.logger.info "Fetching OpenAQ sensors near (#{lat}, #{lon}) within #{radius_km}km"

    response = make_request(endpoint, query_params)
    return [] unless response

    parse_sensors_response(response)
  rescue StandardError => e
    log_error("fetch_sensors_near_location", e)
    []
  end

  # Fetch latest measurements for a specific sensor/location
  # In v3, this returns location metadata with sensor list
  # For actual measurement values, use fetch_sensor_measurements with sensor_id
  # @param location_id [Integer] OpenAQ location ID
  # @param parameters [Array<String>] Specific parameters to fetch
  # @return [Hash] Location data with sensor metadata
  def fetch_latest_measurements(location_id:, parameters: nil)
    endpoint = "/locations/#{location_id}"

    query_params = {}
    query_params[:parameters] = parameters.join(",") if parameters.present?

    Rails.logger.info "Fetching location metadata for OpenAQ location #{location_id}"

    response = make_request(endpoint, query_params)
    return nil unless response

    parse_location_metadata_response(response)
  rescue StandardError => e
    log_error("fetch_latest_measurements", e)
    nil
  end

  # Fetch measurements for a specific sensor over a time range
  # OpenAQ v3 uses /sensors/{id}/measurements endpoint
  # @param sensor_id [Integer] Sensor ID
  # @param date_from [Time] Start time
  # @param date_to [Time] End time
  # @param limit [Integer] Maximum results (default: 1000)
  # @return [Array<Hash>] Array of measurement hashes
  def fetch_sensor_measurements(sensor_id:, date_from:, date_to:, limit: 1000)
    endpoint = "/sensors/#{sensor_id}/measurements"

    query_params = {
      date_from: date_from.utc.iso8601,
      date_to: date_to.utc.iso8601,
      limit: [ limit, 1000 ].min
    }

    Rails.logger.info "Fetching measurements for sensor #{sensor_id} from #{date_from} to #{date_to}"

    response = make_request(endpoint, query_params)
    return [] unless response

    parse_sensor_measurements_response(response)
  rescue StandardError => e
    log_error("fetch_sensor_measurements", e)
    []
  end

  # Fetch measurements for a location over a time range
  # OpenAQ v3 uses /locations/{id}/measurements endpoint
  # @param location_id [Integer] Location ID
  # @param date_from [Time] Start time
  # @param date_to [Time] End time
  # @param limit [Integer] Maximum results (default: 1000)
  # @return [Array<Hash>] Array of measurement hashes
  def fetch_measurements_by_time(location_id:, date_from:, date_to:, limit: 1000)
    endpoint = "/locations/#{location_id}/measurements"

    query_params = {
      date_from: date_from.utc.iso8601,
      date_to: date_to.utc.iso8601,
      limit: [ limit, 1000 ].min
    }

    Rails.logger.info "Fetching measurements for location #{location_id} from #{date_from} to #{date_to}"

    response = make_request(endpoint, query_params)
    return [] unless response

    parse_location_measurements_response(response)
  rescue StandardError => e
    log_error("fetch_measurements_by_time", e)
    []
  end

  # Search for locations by country, city, or name
  # @param country [String] ISO 3166-1 alpha-2 country code (e.g., 'US', 'GB')
  # @param city [String] City name
  # @param name [String] Location name search
  # @param limit [Integer] Maximum results (default: 100)
  # @return [Array<Hash>] Array of location hashes
  def search_locations(country: nil, city: nil, name: nil, limit: 100)
    endpoint = "/locations"

    query_params = { limit: [ limit, 1000 ].min }
    query_params[:country] = country if country.present?
    query_params[:city] = city if city.present?
    query_params[:name] = name if name.present?

    Rails.logger.info "Searching OpenAQ locations: country=#{country}, city=#{city}, name=#{name}"

    response = make_request(endpoint, query_params)
    return [] unless response

    parse_locations_response(response)
  rescue StandardError => e
    log_error("search_locations", e)
    []
  end

  # Fetch available parameters (pollutants) from OpenAQ
  # @return [Array<Hash>] Array of parameter hashes with metadata
  def fetch_available_parameters
    endpoint = "/parameters"

    Rails.logger.info "Fetching available OpenAQ parameters"

    response = make_request(endpoint, {})
    return [] unless response

    parse_parameters_response(response)
  rescue StandardError => e
    log_error("fetch_available_parameters", e)
    []
  end

  # Fetch countries with available data
  # @return [Array<Hash>] Array of country hashes
  def fetch_countries
    endpoint = "/countries"

    Rails.logger.info "Fetching OpenAQ countries"

    response = make_request(endpoint, { limit: 300 })
    return [] unless response

    parse_countries_response(response)
  rescue StandardError => e
    log_error("fetch_countries", e)
    []
  end

  # Check API connectivity and authentication
  # @return [Boolean] true if API is accessible
  def connection_healthy?
    endpoint = "/parameters"
    response = make_request(endpoint, { limit: 1 })
    response.present?
  rescue StandardError
    false
  end

  private

  # Make authenticated request to OpenAQ API
  # @param endpoint [String] API endpoint path
  # @param query_params [Hash] Query parameters
  # @return [HTTParty::Response, nil] Response object or nil on error
  def make_request(endpoint, query_params = {})
    options = {
      query: query_params,
      headers: {
        "X-API-Key" => api_key,
        "Accept" => "application/json"
      },
      timeout: 30
    }

    response = self.class.get(endpoint, options)

    unless response.success?
      Rails.logger.warn "OpenAQ API returned #{response.code}: #{response.body}"
      return nil
    end

    response.parsed_response
  rescue HTTParty::Error, SocketError, Timeout::Error => e
    Rails.logger.error "OpenAQ API connection error: #{e.message}"
    nil
  end

  # Parse sensors/locations response from OpenAQ v3
  def parse_sensors_response(response)
    results = response.dig("results") || []

    results.map do |location|
      {
        openaq_id: location["id"],
        name: location["name"],
        locality: location["locality"], # v3: direct string, not nested
        country: location.dig("country", "name"),
        country_code: location.dig("country", "code"),
        latitude: location.dig("coordinates", "latitude"),
        longitude: location.dig("coordinates", "longitude"),
        parameters: extract_parameters(location),
        sensor_type: determine_sensor_type(location),
        manufacturer: location.dig("provider", "name") || "Unknown",
        provider: location.dig("provider", "name") || "Unknown",
        is_mobile: location["isMobile"] || false,
        is_monitor: location["isMonitor"] || false, # v3: isMonitor field
        first_updated: parse_datetime(location.dig("datetimeFirst", "utc")), # v3: nested datetime
        last_updated: parse_datetime(location.dig("datetimeLast", "utc")), # v3: nested datetime
        distance: location["distance"]&.to_f, # v3: distance from search point
        timezone: location["timezone"],
        instruments: location["instruments"]&.map { |i| i["name"] } || []
      }
    end
  end

  # Parse location metadata response (v3: returns location with sensors list)
  def parse_location_metadata_response(response)
    return nil if response.blank?

    location = response.dig("results", 0)
    return nil unless location

    # Extract parameters from the response (could be in sensors or parameters array)
    parameters_data = location["parameters"] || []
    sensors_data = location["sensors"] || []

    # Parse parameters array (direct structure)
    direct_params = parameters_data.map do |param|
      {
        parameter: param["parameter"],
        value: param["value"]&.to_f,
        unit: param["unit"],
        last_updated: param["lastUpdated"]
      }
    end

    # Parse sensors array (nested structure)
    sensor_params = sensors_data.map do |sensor|
      {
        sensor_id: sensor["id"],
        name: sensor["name"],
        parameter: sensor.dig("parameter", "name"),
        display_name: sensor.dig("parameter", "displayName"),
        units: sensor.dig("parameter", "units")
      }
    end

    {
      location_id: location["location"] || location["id"],
      name: location["name"],
      locality: location["locality"],
      country: location.dig("country", "name"),
      parameters: direct_params.presence || sensor_params,
      sensors: sensor_params
    }
  end

  # Parse array of measurements (v3: from /measurements endpoint)
  # Parse sensor measurements response (v3: /sensors/{id}/measurements)
  # Response structure: results array with value, parameter, period objects
  def parse_sensor_measurements_response(response)
    results = response.dig("results") || []

    results.map do |measurement|
      {
        value: measurement["value"]&.to_f,
        parameter_name: measurement.dig("parameter", "name"),
        units: measurement.dig("parameter", "units"),
        recorded_at: parse_datetime(measurement.dig("period", "datetimeFrom", "utc")),
        period_label: measurement.dig("period", "label"),
        interval: measurement.dig("period", "interval"),
        has_flags: measurement.dig("flagInfo", "hasFlags")
      }
    end
  end

  # Parse location measurements response (from /locations/{id}/measurements)
  # Response structure may differ slightly from sensor measurements
  def parse_location_measurements_response(response)
    results = response.dig("results") || []

    results.map do |measurement|
      {
        location: measurement["location"],
        sensors_id: measurement["sensors_id"],
        parameter: measurement["parameter"],
        value: measurement["value"]&.to_f,
        unit: measurement["unit"],
        date: measurement["date"],
        coordinates: measurement["coordinates"]
      }
    end
  end

  # Parse locations search response
  def parse_locations_response(response)
    results = response.dig("results") || []

    results.map do |location|
      {
        openaq_id: location["id"],
        name: location["name"],
        locality: location.dig("locality", "name"),
        country: location.dig("country", "name"),
        country_code: location.dig("country", "code"),
        latitude: location.dig("coordinates", "latitude"),
        longitude: location.dig("coordinates", "longitude"),
        parameters: extract_parameters(location)
      }
    end
  end

  # Parse parameters response
  def parse_parameters_response(response)
    results = response.dig("results") || []

    results.map do |param|
      {
        id: param["id"],
        name: param["name"],
        display_name: param["displayName"],
        description: param["description"],
        units: param["units"]
      }
    end
  end

  # Parse countries response
  def parse_countries_response(response)
    results = response.dig("results") || []

    results.map do |country|
      {
        code: country["code"],
        name: country["name"],
        locations_count: country["locations"],
        measurements_count: country["measurements"]
      }
    end
  end

  # Extract available parameters from location data (v3: sensors array)
  def extract_parameters(location)
    # Try both v3 API structures: sensors array or parameters array
    sensors = location["sensors"] || []
    parameters = location["parameters"] || []

    # Extract from sensors array (v3 structure with sensors)
    sensor_params = sensors.map { |s| s.dig("parameter", "name") }.compact

    # Extract from parameters array (alternative v3 structure)
    direct_params = parameters.map { |p| p["parameter"] }.compact

    (sensor_params + direct_params).uniq
  end

  # Determine primary sensor type from parameters
  def determine_sensor_type(location)
    params = extract_parameters(location)

    # Check for specific sensor types first (more specific to less specific)
    return "temperature" if params.include?("temperature") && !params.any? { |p| %w[pm25 pm10 no2 o3 so2 co].include?(p) }
    return "humidity" if params.include?("humidity") && !params.any? { |p| %w[pm25 pm10 no2 o3 so2 co temperature].include?(p) }
    return "air_quality" if params.any? { |p| %w[pm25 pm10 no2 o3 so2 co].include?(p) }

    "air_quality" # default
  end

  # Parse datetime string to Time object
  def parse_datetime(datetime_string)
    return nil if datetime_string.blank?

    Time.zone.parse(datetime_string)
  rescue ArgumentError
    nil
  end

  # Validate service configuration
  def validate_configuration!
    if api_key.blank?
      raise ConfigurationError, "OPENAQ_API_KEY environment variable is required"
    end

    if api_key == "your_openaq_api_key_here"
      Rails.logger.warn "OpenAQ API key appears to be a placeholder. Please set a valid API key."
    end
  end

  # Log error with context
  def log_error(method_name, error)
    Rails.logger.error "OpenAQ Service Error in #{method_name}: #{error.message}\n#{error.backtrace.join("\n")}"
  end

  # Custom error class
  class ConfigurationError < StandardError; end
end
