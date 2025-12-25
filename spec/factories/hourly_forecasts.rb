FactoryBot.define do
  factory :hourly_forecast do
    location { nil }
    forecast_time { "2025-12-25 11:53:49" }
    temperature { "9.99" }
    humidity { 1 }
    weather_code { 1 }
    wind_speed { "9.99" }
    precipitation_probability { 1 }
    precipitation { "9.99" }
  end
end
