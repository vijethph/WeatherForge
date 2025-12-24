# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

locations = [
  { name: "San Francisco", latitude: 37.7749, longitude: -122.4194, timezone: "America/Los_Angeles" },
  { name: "London", latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London" },
  { name: "Tokyo", latitude: 35.6762, longitude: 139.6503, timezone: "Asia/Tokyo" }
]

locations.each do |loc_data|
  location = Location.find_or_create_by!(name: loc_data[:name]) do |l|
    l.latitude = loc_data[:latitude]
    l.longitude = loc_data[:longitude]
    l.timezone = loc_data[:timezone]
  end

  puts "Processing #{location.name}..."

  # Generate weather metrics for the last 24 hours (every hour)
  24.times do |i|
    time = (24 - i).hours.ago

    # Skip if metric already exists for this hour (approx)
    next if location.weather_metrics.where(recorded_at: time.beginning_of_hour..time.end_of_hour).exists?

    # Generate somewhat realistic data based on location
    base_temp = case location.name
    when "San Francisco" then 15
    when "London" then 10
    when "Tokyo" then 20
    else 15
    end

    # Add some random variation
    temp = base_temp + rand(-2.0..2.0)
    humidity = rand(40..80)
    wind_speed = rand(5.0..20.0)
    precipitation = rand(0.0..5.0)

    WeatherMetric.create!(
      location: location,
      temperature: temp.round(1),
      humidity: humidity,
      wind_speed: wind_speed.round(1),
      precipitation: precipitation.round(1),
      recorded_at: time
    )
  end
end

puts "Seeding completed!"
