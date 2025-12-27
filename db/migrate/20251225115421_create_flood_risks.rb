class CreateFloodRisks < ActiveRecord::Migration[8.1]
  def change
    create_table :flood_risks do |t|
      t.references :location, null: false, foreign_key: true
      t.decimal :flood_probability, precision: 5, scale: 2
      t.string :flood_severity
      t.text :flood_description
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :flood_risks, [ :location_id, :recorded_at ], unique: true
  end
end
