FactoryBot.define do
  factory :air_quality do
    location { nil }
    pm2_5 { "9.99" }
    pm10 { "9.99" }
    o3 { "9.99" }
    no2 { "9.99" }
    so2 { "9.99" }
    aqi_level { 1 }
    recorded_at { "2025-12-25 11:54:14" }
  end
end
