FactoryBot.define do
  factory :flood_risk do
    location { nil }
    flood_probability { "9.99" }
    flood_severity { "MyString" }
    flood_description { "MyText" }
    recorded_at { "2025-12-25 11:54:21" }
  end
end
