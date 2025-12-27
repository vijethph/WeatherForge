class AddFieldsToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :elevation, :decimal, precision: 8, scale: 2
    add_column :locations, :country, :string

    add_index :locations, [ :latitude, :longitude ], unique: true
  end
end
