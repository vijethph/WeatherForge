# frozen_string_literal: true

require "httparty"

class WeatherService
  include HTTParty

  BASE_URL = "https://api.open-meteo.com/v1"

  attr_reader :location

  def initialize(location)
    @location = location
  end

  # Fetch current weather with 11 metrics
  def fetch_current_weather
    url = "#{BASE_URL}/forecast"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      current: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,cloud_cover,pressure_msl,visibility,apparent_temperature",
      timezone: "auto"
    }

    Rails.logger.info("Fetching current weather for #{location.name}")
    response = HTTParty.get(url, query: params)

    return nil unless response.success?

    Rails.logger.info("Current weather data received for #{location.name}")
    parse_current_weather(response)
  rescue StandardError => e
    Rails.logger.error("Weather service error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Fetch hourly forecast for next 24 hours
  def fetch_hourly_forecast
    url = "#{BASE_URL}/forecast"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      hourly: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation_probability,precipitation",
      forecast_days: 1,
      timezone: "auto"
    }

    Rails.logger.info("Fetching hourly forecast for #{location.name}")
    response = HTTParty.get(url, query: params)

    return nil unless response.success?

    Rails.logger.info("Hourly forecast data received for #{location.name}")
    parse_hourly_forecast(response)
  rescue StandardError => e
    Rails.logger.error("Hourly forecast error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Fetch 10-day historical weather
  def fetch_historical_weather
    start_date = 10.days.ago.to_date
    end_date = Date.yesterday

    url = "https://archive-api.open-meteo.com/v1/archive"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      start_date: start_date.to_s,
      end_date: end_date.to_s,
      daily: "temperature_2m_max,temperature_2m_min,temperature_2m_mean,precipitation_sum,weather_code",
      timezone: "auto"
    }

    Rails.logger.info("Fetching historical weather for #{location.name}")
    response = HTTParty.get(url, query: params)

    return nil unless response.success?

    Rails.logger.info("Historical weather data received for #{location.name}")
    parse_historical_weather(response)
  rescue StandardError => e
    Rails.logger.error("Historical weather error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Fetch marine weather (waves, water temperature)
  def fetch_marine_weather
    url = "https://marine-api.open-meteo.com/v1/marine"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      current: "wave_height,wave_period,wave_direction,ocean_current_velocity,ocean_current_direction",
      hourly: "wave_height,wave_period,ocean_current_velocity",
      timezone: "auto"
    }

    Rails.logger.info("Fetching marine weather for #{location.name} at (#{location.latitude}, #{location.longitude})")
    response = HTTParty.get(url, query: params)

    if response.success?
      Rails.logger.info("Marine weather data received for #{location.name}: #{response.parsed_response.inspect}")
      parse_marine_weather(response)
    else
      Rails.logger.warn("Marine weather API returned non-success status for #{location.name}: #{response.code}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Marine weather error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Fetch air quality data
  def fetch_air_quality
    url = "https://air-quality-api.open-meteo.com/v1/air-quality"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      current: "pm2_5,pm10,ozone,nitrogen_dioxide,sulphur_dioxide",
      timezone: "auto"
    }

    Rails.logger.info("Fetching air quality for #{location.name}")
    response = HTTParty.get(url, query: params)

    return nil unless response.success?

    Rails.logger.info("Air quality data received for #{location.name}")
    parse_air_quality(response)
  rescue StandardError => e
    Rails.logger.error("Air quality error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Fetch flood risk data
  def fetch_flood_risk
    url = "https://flood-api.open-meteo.com/v1/flood"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      daily: "river_discharge",
      forecast_days: 7,
      timezone: "auto"
    }

    Rails.logger.info("Fetching flood risk for #{location.name}")
    response = HTTParty.get(url, query: params)

    return nil unless response.success?

    Rails.logger.info("Flood risk data received for #{location.name}")
    parse_flood_risk(response)
  rescue StandardError => e
    Rails.logger.error("Flood risk error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Get elevation data
  def fetch_elevation
    url = "#{BASE_URL}/elevation"

    params = {
      latitude: location.latitude,
      longitude: location.longitude
    }

    Rails.logger.info("Fetching elevation for #{location.name}")
    response = HTTParty.get(url, query: params)

    return nil unless response.success?

    elevation = response.dig("elevation", 0)
    Rails.logger.info("Elevation data received for #{location.name}: #{elevation}m")
    elevation
  rescue StandardError => e
    Rails.logger.error("Elevation error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Class method: Search locations by name (geocoding)
  def self.search_locations(query, limit = 10)
    url = "https://geocoding-api.open-meteo.com/v1/search"

    params = {
      name: query,
      count: limit,
      language: "en",
      format: "json"
    }

    Rails.logger.info("Searching locations for query: #{query}")
    response = HTTParty.get(url, query: params)

    return [] unless response.success?

    results = parse_search_results(response)
    Rails.logger.info("Found #{results.count} location(s) for query: #{query}")
    results
  rescue StandardError => e
    Rails.logger.error("Geocoding error for query '#{query}': #{e.message}\n#{e.backtrace.join("\n")}")
    []
  end

  private

  # Parse current weather response
  def parse_current_weather(response)
    current = response["current"]

    {
      temperature: current["temperature_2m"],
      feels_like: current["apparent_temperature"],
      humidity: current["relative_humidity_2m"],
      wind_speed: current["wind_speed_10m"],
      wind_direction: current["wind_direction_10m"],
      wind_gust: current["wind_gusts_10m"],
      precipitation: current["precipitation"],
      weather_code: current["weather_code"],
      cloud_cover: current["cloud_cover"],
      pressure: current["pressure_msl"],
      visibility: current["visibility"]
    }
  end

  # Parse hourly forecast response
  def parse_hourly_forecast(response)
    hourly = response["hourly"]
    times = hourly["time"]
    temps = hourly["temperature_2m"]
    humidities = hourly["relative_humidity_2m"]
    codes = hourly["weather_code"]
    winds = hourly["wind_speed_10m"]
    precip_probs = hourly["precipitation_probability"]
    precips = hourly["precipitation"]

    forecasts = []
    times.each_with_index do |time, idx|
      forecasts << {
        forecast_time: Time.zone.parse(time),
        temperature: temps[idx],
        humidity: humidities[idx],
        weather_code: codes[idx],
        wind_speed: winds[idx],
        precipitation_probability: precip_probs[idx],
        precipitation: precips[idx]
      }
    end

    forecasts
  end

  # Parse historical weather response
  def parse_historical_weather(response)
    daily = response["daily"]
    dates = daily["time"]
    max_temps = daily["temperature_2m_max"]
    min_temps = daily["temperature_2m_min"]
    avg_temps = daily["temperature_2m_mean"]
    precips = daily["precipitation_sum"]
    codes = daily["weather_code"]

    histories = []
    dates.each_with_index do |date, idx|
      histories << {
        weather_date: Date.parse(date),
        max_temperature: max_temps[idx],
        min_temperature: min_temps[idx],
        avg_temperature: avg_temps[idx],
        total_precipitation: precips[idx],
        weather_code: codes[idx]
      }
    end

    histories
  end

  # Parse marine weather response
  def parse_marine_weather(response)
    return nil unless response["current"].present?

    current = response["current"]

    {
      wave_height: current["wave_height"]&.to_f,
      wave_period: current["wave_period"]&.to_f,
      water_temperature: current["ocean_current_velocity"]&.to_f # Using ocean current as proxy for activity
    }
  end

  # Parse air quality response
  def parse_air_quality(response)
    current = response["current"]

    {
      pm2_5: current["pm2_5"],
      pm10: current["pm10"],
      o3: current["ozone"],
      no2: current["nitrogen_dioxide"],
      so2: current["sulphur_dioxide"],
      aqi_level: calculate_aqi(current)
    }
  end

  # Parse flood risk response
  def parse_flood_risk(response)
    return nil unless response["daily"].present?

    daily = response["daily"]
    river_discharge = daily["river_discharge"]

    return nil unless river_discharge.present? && river_discharge.any?

    # Use first value as current flood risk indicator
    discharge_value = river_discharge.first.to_f

    # Normalize discharge to probability (0-1 scale)
    # Assuming typical discharge values range from 0-1000 m³/s
    normalized_value = [ discharge_value / 1000.0, 1.0 ].min

    {
      flood_probability: normalized_value,
      flood_severity: determine_severity(normalized_value),
      flood_description: flood_description(normalized_value)
    }
  end

  # Parse geocoding search results
  def self.parse_search_results(response)
    return [] unless response["results"].present?

    response["results"].map do |result|
      {
        name: build_location_name(result),
        latitude: result["latitude"],
        longitude: result["longitude"],
        country: result["country"],
        timezone: result["timezone"]
      }
    end
  end

  # Build human-readable location name
  def self.build_location_name(result)
    parts = [ result["name"] ]
    parts << result["admin1"] if result["admin1"].present?
    parts << result["country"] if result["country"].present?
    parts.join(", ")
  end

  # Calculate AQI level from PM2.5 value
  def calculate_aqi(air_data)
    pm2_5 = air_data["pm2_5"].to_f

    case pm2_5
    when 0..12
      1 # Good
    when 12.1..35.4
      2 # Fair
    when 35.5..55.4
      3 # Moderate
    when 55.5..150.4
      4 # Poor
    else
      5 # Very Poor
    end
  end

  # Determine flood severity level
  def determine_severity(flood_value)
    case flood_value.to_f
    when 0..0.2
      "low"
    when 0.2..0.5
      "moderate"
    else
      "high"
    end
  end

  # Generate flood description
  def flood_description(flood_value)
    case flood_value.to_f
    when 0..0.2
      "Low flood probability"
    when 0.2..0.5
      "Moderate flood probability - Monitor situation"
    else
      "High flood probability - Take precautions"
    end
  end
end
