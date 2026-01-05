FactoryBot.define do
  factory :environmental_reading do
    association :environmental_sensor

    value { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    unit { %w[µg/m³ ppm °C % ppb].sample }
    recorded_at { Faker::Time.between(from: 24.hours.ago, to: Time.current) }
    parameter_name { %w[pm25 pm10 o3 no2 so2 co bc temperature humidity].sample }
    raw_data { {} }

    trait :pm25 do
      parameter_name { "pm25" }
      value { Faker::Number.between(from: 0.0, to: 150.0).round(4) }
      unit { "µg/m³" }
    end

    trait :temperature do
      parameter_name { "temperature" }
      value { Faker::Number.between(from: -10.0, to: 40.0).round(2) }
      unit { "°C" }
    end

    trait :high_value do
      value { Faker::Number.between(from: 100.0, to: 200.0).round(4) }
    end

    trait :recent do
      recorded_at { 5.minutes.ago }
    end

    trait :old do
      recorded_at { 48.hours.ago }
    end
  end
end
