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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_105653) do
  create_table "locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.string "name", null: false
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "weather_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "humidity"
    t.integer "location_id", null: false
    t.decimal "precipitation", precision: 5, scale: 2
    t.datetime "recorded_at", null: false
    t.decimal "temperature", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.decimal "wind_speed", precision: 5, scale: 2
    t.index ["location_id", "recorded_at"], name: "index_weather_metrics_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_weather_metrics_on_location_id"
  end

  add_foreign_key "weather_metrics", "locations"
end
