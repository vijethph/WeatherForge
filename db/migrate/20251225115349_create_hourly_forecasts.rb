class CreateHourlyForecasts < ActiveRecord::Migration[8.1]
  def change
    create_table :hourly_forecasts do |t|
      t.references :location, null: false, foreign_key: true
      t.datetime :forecast_time, null: false
      t.decimal :temperature, precision: 5, scale: 2
      t.integer :humidity
      t.integer :weather_code
      t.decimal :wind_speed, precision: 5, scale: 2
      t.integer :precipitation_probability
      t.decimal :precipitation, precision: 5, scale: 2

      t.timestamps
    end

    add_index :hourly_forecasts, [ :location_id, :forecast_time ], unique: true
    add_index :hourly_forecasts, :forecast_time
  end
end
