FactoryBot.define do
  factory :weather_metric do
    association :location
    temperature { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    feels_like { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    humidity { Faker::Number.between(from: 0, to: 100) }
    wind_speed { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    wind_direction { Faker::Number.between(from: 0, to: 360) }
    wind_gust { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    precipitation { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    weather_code { Faker::Number.between(from: 0, to: 99) }
    cloud_cover { Faker::Number.between(from: 0, to: 100) }
    pressure { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    visibility { Faker::Number.between(from: 0, to: 10000) }
    recorded_at { Time.current }
  end
end
