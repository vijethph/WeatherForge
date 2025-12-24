class SyncWeatherJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Starting weather sync for all locations")

    Location.all.each do |location|
      begin
        service = WeatherService.new(location)
        weather_data = service.fetch_current_weather

        if weather_data.present?
          WeatherMetric.create!(
            location: location,
            temperature: weather_data[:temperature],
            humidity: weather_data[:humidity],
            wind_speed: weather_data[:wind_speed],
            precipitation: weather_data[:precipitation],
            recorded_at: Time.current
          )

          broadcast_weather_update(location)
          Rails.logger.info("Weather data synced for #{location.name}")
        else
          Rails.logger.warn("No weather data available for #{location.name}")
        end
      rescue StandardError => e
        Rails.logger.error("Failed to sync weather for #{location.name}: #{e.message}\n#{e.backtrace.join("\n")}")
      end
    end

    Rails.logger.info("Weather sync completed")
  end

  private

  def broadcast_weather_update(location)
    Turbo::StreamsChannel.broadcast_update_to(
      "location_updates",
      target: "weather_card_#{location.id}",
      partial: "dashboards/weather_card",
      locals: { location: location }
    )
  end
end
