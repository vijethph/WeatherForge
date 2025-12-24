FactoryBot.define do
  factory :location do
    name { Faker::Address.city }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    timezone { "UTC" }
    description { Faker::Lorem.sentence }
  end
end
