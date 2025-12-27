class AddFieldsToWeatherMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :weather_metrics, :feels_like, :decimal, precision: 5, scale: 2
    add_column :weather_metrics, :wind_direction, :integer
    add_column :weather_metrics, :wind_gust, :decimal, precision: 5, scale: 2
    add_column :weather_metrics, :weather_code, :integer
    add_column :weather_metrics, :cloud_cover, :integer
    add_column :weather_metrics, :pressure, :decimal, precision: 7, scale: 2
    add_column :weather_metrics, :visibility, :integer

    add_index :weather_metrics, :recorded_at
  end
end
