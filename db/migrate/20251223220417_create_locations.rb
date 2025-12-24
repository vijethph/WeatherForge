class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.text :description
      t.string :timezone, default: 'UTC'

      t.timestamps
    end

    add_index :locations, :name, unique: true
  end
end
