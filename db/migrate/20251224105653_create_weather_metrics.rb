class CreateWeatherMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :weather_metrics do |t|
      t.references :location, null: false, foreign_key: true
      t.decimal :temperature, precision: 5, scale: 2, null: false
      t.integer :humidity
      t.decimal :wind_speed, precision: 5, scale: 2
      t.decimal :precipitation, precision: 5, scale: 2
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :weather_metrics, [ :location_id, :recorded_at ], unique: true
  end
end
