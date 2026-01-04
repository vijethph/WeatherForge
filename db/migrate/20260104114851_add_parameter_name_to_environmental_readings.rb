class AddParameterNameToEnvironmentalReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :environmental_readings, :parameter_name, :string
    add_index :environmental_readings, :parameter_name
  end
end
