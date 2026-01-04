FactoryBot.define do
  factory :environmental_sensor do
    association :location

    sequence(:name) { |n| "#{Faker::Company.name} Sensor #{n}" }
    sensor_type { %w[air_quality temperature humidity water_quality].sample }
    manufacturer { Faker::Company.name }
    installation_date { Faker::Date.between(from: 2.years.ago, to: Date.today) }
    last_maintenance { Faker::Date.between(from: 6.months.ago, to: Date.today) }
    status { "active" }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    metadata { {} }

    trait :active do
      status { "active" }
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :maintenance do
      status { "maintenance" }
    end

    trait :air_quality do
      sensor_type { "air_quality" }
    end

    trait :temperature do
      sensor_type { "temperature" }
    end

    trait :with_readings do
      after(:create) do |sensor|
        create_list(:environmental_reading, 5, environmental_sensor: sensor)
      end
    end

    trait :with_alerts do
      after(:create) do |sensor|
        create_list(:environmental_alert, 2, environmental_sensor: sensor)
      end
    end
  end
end
