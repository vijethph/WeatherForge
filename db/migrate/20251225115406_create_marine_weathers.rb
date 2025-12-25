class CreateMarineWeathers < ActiveRecord::Migration[8.1]
  def change
    create_table :marine_weathers do |t|
      t.references :location, null: false, foreign_key: true
      t.decimal :wave_height, precision: 5, scale: 2
      t.decimal :wave_period, precision: 5, scale: 2
      t.decimal :water_temperature, precision: 5, scale: 2
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :marine_weathers, [ :location_id, :recorded_at ], unique: true
  end
end
