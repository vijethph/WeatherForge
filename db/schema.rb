# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_25_115421) do
  create_table "air_qualities", force: :cascade do |t|
    t.integer "aqi_level"
    t.datetime "created_at", null: false
    t.integer "location_id", null: false
    t.decimal "no2", precision: 6, scale: 2
    t.decimal "o3", precision: 6, scale: 2
    t.decimal "pm10", precision: 6, scale: 2
    t.decimal "pm2_5", precision: 6, scale: 2
    t.datetime "recorded_at", null: false
    t.decimal "so2", precision: 6, scale: 2
    t.datetime "updated_at", null: false
    t.index ["location_id", "recorded_at"], name: "index_air_qualities_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_air_qualities_on_location_id"
  end

  create_table "flood_risks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "flood_description"
    t.decimal "flood_probability", precision: 5, scale: 2
    t.string "flood_severity"
    t.integer "location_id", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "recorded_at"], name: "index_flood_risks_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_flood_risks_on_location_id"
  end

  create_table "historical_weathers", force: :cascade do |t|
    t.decimal "avg_temperature", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.integer "location_id", null: false
    t.decimal "max_temperature", precision: 5, scale: 2
    t.decimal "min_temperature", precision: 5, scale: 2
    t.decimal "total_precipitation", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.integer "weather_code"
    t.date "weather_date", null: false
    t.index ["location_id", "weather_date"], name: "index_historical_weathers_on_location_id_and_weather_date", unique: true
    t.index ["location_id"], name: "index_historical_weathers_on_location_id"
    t.index ["weather_date"], name: "index_historical_weathers_on_weather_date"
  end

  create_table "hourly_forecasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "forecast_time", null: false
    t.integer "humidity"
    t.integer "location_id", null: false
    t.decimal "precipitation", precision: 5, scale: 2
    t.integer "precipitation_probability"
    t.decimal "temperature", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.integer "weather_code"
    t.decimal "wind_speed", precision: 5, scale: 2
    t.index ["forecast_time"], name: "index_hourly_forecasts_on_forecast_time"
    t.index ["location_id", "forecast_time"], name: "index_hourly_forecasts_on_location_id_and_forecast_time", unique: true
    t.index ["location_id"], name: "index_hourly_forecasts_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "elevation", precision: 8, scale: 2
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.string "name", null: false
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "marine_weathers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "location_id", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "water_temperature", precision: 5, scale: 2
    t.decimal "wave_height", precision: 5, scale: 2
    t.decimal "wave_period", precision: 5, scale: 2
    t.index ["location_id", "recorded_at"], name: "index_marine_weathers_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_marine_weathers_on_location_id"
  end

  create_table "weather_metrics", force: :cascade do |t|
    t.integer "cloud_cover"
    t.datetime "created_at", null: false
    t.decimal "feels_like", precision: 5, scale: 2
    t.integer "humidity"
    t.integer "location_id", null: false
    t.decimal "precipitation", precision: 5, scale: 2
    t.decimal "pressure", precision: 7, scale: 2
    t.datetime "recorded_at", null: false
    t.decimal "temperature", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.integer "visibility"
    t.integer "weather_code"
    t.integer "wind_direction"
    t.decimal "wind_gust", precision: 5, scale: 2
    t.decimal "wind_speed", precision: 5, scale: 2
    t.index ["location_id", "recorded_at"], name: "index_weather_metrics_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_weather_metrics_on_location_id"
    t.index ["recorded_at"], name: "index_weather_metrics_on_recorded_at"
  end

  add_foreign_key "air_qualities", "locations"
  add_foreign_key "flood_risks", "locations"
  add_foreign_key "historical_weathers", "locations"
  add_foreign_key "hourly_forecasts", "locations"
  add_foreign_key "marine_weathers", "locations"
  add_foreign_key "weather_metrics", "locations"
end
