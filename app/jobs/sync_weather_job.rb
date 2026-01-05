# frozen_string_literal: true

class SyncWeatherJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Starting comprehensive weather sync for all locations")

    Location.find_each do |location|
      sync_current_weather(location)
      sync_hourly_forecast(location)
      sync_historical_weather(location)
      sync_marine_weather(location)
      sync_air_quality(location)
      sync_flood_risk(location)
      update_elevation(location)

      broadcast_location_updates(location)
    rescue StandardError => e
      Rails.logger.error("Failed to sync weather for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    Rails.logger.info("Comprehensive weather sync completed")
  end

  private

  def sync_current_weather(location)
    service = WeatherService.new(location)
    weather_data = service.fetch_current_weather

    return unless weather_data.present?

    WeatherMetric.create!(
      location: location,
      temperature: weather_data[:temperature],
      feels_like: weather_data[:feels_like],
      humidity: weather_data[:humidity],
      wind_speed: weather_data[:wind_speed],
      wind_direction: weather_data[:wind_direction],
      wind_gust: weather_data[:wind_gust],
      precipitation: weather_data[:precipitation],
      weather_code: weather_data[:weather_code],
      cloud_cover: weather_data[:cloud_cover],
      pressure: weather_data[:pressure],
      visibility: weather_data[:visibility],
      recorded_at: Time.current
    )

    Rails.logger.info("Current weather synced for #{location.name}")
  rescue StandardError => e
    Rails.logger.error("Current weather sync error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def sync_hourly_forecast(location)
    service = WeatherService.new(location)
    forecasts = service.fetch_hourly_forecast

    return unless forecasts.present?

    forecasts.each do |forecast_data|
      HourlyForecast.find_or_create_by!(
        location: location,
        forecast_time: forecast_data[:forecast_time]
      ) do |forecast|
        forecast.temperature = forecast_data[:temperature]
        forecast.humidity = forecast_data[:humidity]
        forecast.weather_code = forecast_data[:weather_code]
        forecast.wind_speed = forecast_data[:wind_speed]
        forecast.precipitation_probability = forecast_data[:precipitation_probability]
        forecast.precipitation = forecast_data[:precipitation]
      end
    end

    Rails.logger.info("Hourly forecast synced for #{location.name} (#{forecasts.count} forecasts)")
  rescue StandardError => e
    Rails.logger.error("Hourly forecast sync error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def sync_historical_weather(location)
    service = WeatherService.new(location)
    histories = service.fetch_historical_weather

    return unless histories.present?

    histories.each do |history_data|
      HistoricalWeather.find_or_create_by!(
        location: location,
        weather_date: history_data[:weather_date]
      ) do |history|
        history.max_temperature = history_data[:max_temperature]
        history.min_temperature = history_data[:min_temperature]
        history.avg_temperature = history_data[:avg_temperature]
        history.total_precipitation = history_data[:total_precipitation]
        history.weather_code = history_data[:weather_code]
      end
    end

    Rails.logger.info("Historical weather synced for #{location.name} (#{histories.count} days)")
  rescue StandardError => e
    Rails.logger.error("Historical weather sync error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def sync_marine_weather(location)
    service = WeatherService.new(location)
    marine_data = service.fetch_marine_weather

    return unless marine_data.present?

    MarineWeather.create!(
      location: location,
      wave_height: marine_data[:wave_height],
      wave_period: marine_data[:wave_period],
      water_temperature: marine_data[:water_temperature],
      recorded_at: Time.current
    )

    Rails.logger.info("Marine weather synced for #{location.name}")
  rescue StandardError => e
    Rails.logger.error("Marine weather sync error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def sync_air_quality(location)
    service = WeatherService.new(location)
    air_data = service.fetch_air_quality

    return unless air_data.present?

    AirQuality.create!(
      location: location,
      pm2_5: air_data[:pm2_5],
      pm10: air_data[:pm10],
      o3: air_data[:o3],
      no2: air_data[:no2],
      so2: air_data[:so2],
      aqi_level: air_data[:aqi_level],
      recorded_at: Time.current
    )

    Rails.logger.info("Air quality synced for #{location.name}")
  rescue StandardError => e
    Rails.logger.error("Air quality sync error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def sync_flood_risk(location)
    service = WeatherService.new(location)
    flood_data = service.fetch_flood_risk

    return unless flood_data.present?

    FloodRisk.create!(
      location: location,
      flood_probability: flood_data[:flood_probability],
      flood_severity: flood_data[:flood_severity],
      flood_description: flood_data[:flood_description],
      recorded_at: Time.current
    )

    Rails.logger.info("Flood risk synced for #{location.name}")
  rescue StandardError => e
    Rails.logger.error("Flood risk sync error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def update_elevation(location)
    return if location.elevation.present?

    service = WeatherService.new(location)
    elevation = service.fetch_elevation

    return unless elevation.present?

    location.update(elevation: elevation)
    Rails.logger.info("Elevation updated for #{location.name}: #{elevation}m")
  rescue StandardError => e
    Rails.logger.error("Elevation update error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def broadcast_location_updates(location)
    Turbo::StreamsChannel.broadcast_update_to(
      "location_updates",
      target: "weather_card_#{location.id}",
      partial: "dashboards/weather_card",
      locals: { location: location }
    )

    broadcast_chart_updates(location)
  rescue StandardError => e
    Rails.logger.error("Broadcast error for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def broadcast_chart_updates(location)
    # Broadcast chart updates (these are in dashboards/charts/)
    %w[temperature_chart humidity_chart hourly_forecast historical_chart].each do |target|
      Turbo::StreamsChannel.broadcast_update_to(
        "location_updates",
        target: target,
        partial: "dashboards/charts/#{target}",
        locals: { location: location }
      )
    end

    # Broadcast environmental updates (these are in dashboards/)
    %w[marine_weather air_quality flood_risk].each do |target|
      Turbo::StreamsChannel.broadcast_update_to(
        "location_updates",
        target: target,
        partial: "dashboards/#{target}",
        locals: { locations: Location.all }
      )
    end
  end
end
