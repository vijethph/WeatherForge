FactoryBot.define do
  factory :weather_metric do
    association :location
    temperature { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    humidity { Faker::Number.between(from: 0, to: 100) }
    wind_speed { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    precipitation { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    recorded_at { Time.current }
  end
end
