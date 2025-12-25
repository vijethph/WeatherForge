FactoryBot.define do
  factory :historical_weather do
    location { nil }
    weather_date { "2025-12-25" }
    max_temperature { "9.99" }
    min_temperature { "9.99" }
    avg_temperature { "9.99" }
    total_precipitation { "9.99" }
    weather_code { 1 }
  end
end
