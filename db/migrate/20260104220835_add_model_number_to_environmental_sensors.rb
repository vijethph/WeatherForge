class AddModelNumberToEnvironmentalSensors < ActiveRecord::Migration[8.1]
  def change
    add_column :environmental_sensors, :model_number, :string
  end
end
