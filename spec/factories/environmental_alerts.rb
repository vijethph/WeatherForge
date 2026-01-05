FactoryBot.define do
  factory :environmental_alert do
    association :environmental_sensor
    association :environmental_reading, factory: :environmental_reading

    alert_type { %w[threshold_exceeded anomaly sensor_failure zone_alert network_issue].sample }
    severity { %w[low medium high critical].sample }
    message { Faker::Lorem.sentence }
    resolved_at { nil }
    metadata { {} }

    trait :active do
      resolved_at { nil }
    end

    trait :resolved do
      resolved_at { Faker::Time.between(from: 1.hour.ago, to: Time.current) }
    end

    trait :critical do
      severity { "critical" }
      alert_type { "threshold_exceeded" }
    end

    trait :high do
      severity { "high" }
    end

    trait :medium do
      severity { "medium" }
    end

    trait :low do
      severity { "low" }
    end

    trait :threshold_exceeded do
      alert_type { "threshold_exceeded" }
      message { "Reading exceeded safe threshold" }
    end

    trait :anomaly do
      alert_type { "anomaly" }
      message { "Anomalous reading detected" }
    end

    trait :sensor_failure do
      alert_type { "sensor_failure" }
      message { "Sensor malfunction detected" }
    end

    trait :network_issue do
      alert_type { "network_issue" }
      message { "Network connectivity issue" }
    end

    trait :zone_alert do
      alert_type { "zone_alert" }
      message { "Zone threshold violation" }
    end
  end
end
