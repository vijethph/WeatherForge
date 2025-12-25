class CreateHistoricalWeathers < ActiveRecord::Migration[8.1]
  def change
    create_table :historical_weathers do |t|
      t.references :location, null: false, foreign_key: true
      t.date :weather_date, null: false
      t.decimal :max_temperature, precision: 5, scale: 2
      t.decimal :min_temperature, precision: 5, scale: 2
      t.decimal :avg_temperature, precision: 5, scale: 2
      t.decimal :total_precipitation, precision: 5, scale: 2
      t.integer :weather_code

      t.timestamps
    end

    add_index :historical_weathers, [ :location_id, :weather_date ], unique: true
    add_index :historical_weathers, :weather_date
  end
end
