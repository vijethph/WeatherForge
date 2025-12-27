class CreateAirQualities < ActiveRecord::Migration[8.1]
  def change
    create_table :air_qualities do |t|
      t.references :location, null: false, foreign_key: true
      t.decimal :pm2_5, precision: 6, scale: 2
      t.decimal :pm10, precision: 6, scale: 2
      t.decimal :o3, precision: 6, scale: 2
      t.decimal :no2, precision: 6, scale: 2
      t.decimal :so2, precision: 6, scale: 2
      t.integer :aqi_level
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :air_qualities, [ :location_id, :recorded_at ], unique: true
  end
end
