require "httparty"

class WeatherService
  BASE_URL = "https://api.open-meteo.com/v1"

  attr_reader :location

  def initialize(location)
    @location = location
  end

  def fetch_current_weather
    url = "#{BASE_URL}/forecast"

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      current: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation",
      timezone: "auto"
    }

    Rails.logger.info("Fetching weather for #{location.name}")
    response = HTTParty.get(url, query: params)

    if response.success?
      Rails.logger.info("Weather data received for #{location.name}")
      parse_weather_response(response)
    else
      Rails.logger.error("Failed to fetch weather for #{location.name}: HTTP #{response.code}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Weather service error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  private

  def parse_weather_response(response)
    current = response["current"]

    {
      temperature: current["temperature_2m"],
      humidity: current["relative_humidity_2m"],
      wind_speed: current["wind_speed_10m"],
      precipitation: current["precipitation"]
    }
  end
end
