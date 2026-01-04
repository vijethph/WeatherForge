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

ActiveRecord::Schema[8.1].define(version: 2026_01_04_220835) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"
  enable_extension "tiger.postgis_tiger_geocoder"
  enable_extension "topology.postgis_topology"

  create_table "air_qualities", force: :cascade do |t|
    t.integer "aqi_level"
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
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

  create_table "environmental_alerts", force: :cascade do |t|
    t.string "alert_type", null: false
    t.datetime "created_at", null: false
    t.bigint "environmental_reading_id"
    t.bigint "environmental_sensor_id", null: false
    t.text "message", null: false
    t.jsonb "metadata", default: {}
    t.datetime "resolved_at"
    t.string "severity", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_type"], name: "index_environmental_alerts_on_alert_type"
    t.index ["created_at"], name: "index_alerts_critical_active", where: "(((severity)::text = 'critical'::text) AND (resolved_at IS NULL))"
    t.index ["created_at"], name: "index_environmental_alerts_on_created_at"
    t.index ["environmental_reading_id"], name: "index_environmental_alerts_on_environmental_reading_id"
    t.index ["environmental_sensor_id", "created_at"], name: "index_alerts_sensor_created"
    t.index ["environmental_sensor_id", "resolved_at"], name: "index_alerts_sensor_resolved"
    t.index ["environmental_sensor_id"], name: "index_environmental_alerts_on_environmental_sensor_id"
    t.index ["resolved_at"], name: "index_environmental_alerts_on_resolved_at"
    t.index ["severity", "created_at"], name: "index_alerts_active_by_severity", where: "(resolved_at IS NULL)"
    t.index ["severity", "resolved_at"], name: "index_alerts_severity_resolved"
    t.index ["severity"], name: "index_environmental_alerts_on_severity"
  end

  create_table "environmental_readings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "environmental_sensor_id", null: false
    t.string "parameter_name"
    t.jsonb "raw_data", default: {}
    t.datetime "recorded_at", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.float "value", null: false
    t.index ["environmental_sensor_id", "recorded_at"], name: "index_readings_sensor_recorded_unique", unique: true
    t.index ["environmental_sensor_id", "recorded_at"], name: "index_readings_sensor_time_range"
    t.index ["environmental_sensor_id", "value"], name: "index_readings_sensor_value"
    t.index ["environmental_sensor_id"], name: "index_environmental_readings_on_environmental_sensor_id"
    t.index ["parameter_name"], name: "index_environmental_readings_on_parameter_name"
    t.index ["recorded_at"], name: "index_environmental_readings_on_recorded_at"
    t.index ["value"], name: "index_environmental_readings_on_value"
  end

  create_table "environmental_sensors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.geography "geom", limit: {srid: 4326, type: "geometry", geographic: true}
    t.date "installation_date", null: false
    t.date "last_maintenance"
    t.float "latitude", null: false
    t.bigint "location_id"
    t.float "longitude", null: false
    t.string "manufacturer", null: false
    t.jsonb "metadata", default: {}
    t.string "model_number"
    t.string "name", null: false
    t.string "sensor_type", default: "air_quality", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["geom"], name: "index_environmental_sensors_on_geom", using: :gist
    t.index ["installation_date"], name: "index_environmental_sensors_on_installation_date"
    t.index ["latitude"], name: "index_environmental_sensors_on_latitude"
    t.index ["location_id", "status"], name: "index_sensors_on_location_and_status"
    t.index ["location_id"], name: "index_environmental_sensors_on_location_id"
    t.index ["longitude"], name: "index_environmental_sensors_on_longitude"
    t.index ["name"], name: "index_environmental_sensors_on_name"
    t.index ["sensor_type", "status"], name: "index_sensors_on_type_and_status"
    t.index ["sensor_type"], name: "index_environmental_sensors_on_sensor_type"
    t.index ["status"], name: "index_environmental_sensors_on_status"
  end

  create_table "flood_risks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "flood_description"
    t.decimal "flood_probability", precision: 5, scale: 2
    t.string "flood_severity"
    t.bigint "location_id", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "recorded_at"], name: "index_flood_risks_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_flood_risks_on_location_id"
  end

  create_table "historical_weathers", force: :cascade do |t|
    t.decimal "avg_temperature", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
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
    t.bigint "location_id", null: false
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
    t.geography "geom", limit: {srid: 4326, type: "geometry", geographic: true}
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.string "name", null: false
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["geom"], name: "index_locations_on_geom", using: :gist
    t.index ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "marine_weathers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "water_temperature", precision: 5, scale: 2
    t.decimal "wave_height", precision: 5, scale: 2
    t.decimal "wave_period", precision: 5, scale: 2
    t.index ["location_id", "recorded_at"], name: "index_marine_weathers_on_location_id_and_recorded_at", unique: true
    t.index ["location_id"], name: "index_marine_weathers_on_location_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "weather_metrics", force: :cascade do |t|
    t.integer "cloud_cover"
    t.datetime "created_at", null: false
    t.decimal "feels_like", precision: 5, scale: 2
    t.integer "humidity"
    t.bigint "location_id", null: false
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
  add_foreign_key "environmental_alerts", "environmental_readings"
  add_foreign_key "environmental_alerts", "environmental_sensors"
  add_foreign_key "environmental_readings", "environmental_sensors"
  add_foreign_key "environmental_sensors", "locations"
  add_foreign_key "flood_risks", "locations"
  add_foreign_key "historical_weathers", "locations"
  add_foreign_key "hourly_forecasts", "locations"
  add_foreign_key "marine_weathers", "locations"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "weather_metrics", "locations"
end
