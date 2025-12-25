require 'rails_helper'

RSpec.describe HistoricalWeather, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      location = create(:location)
      historical_weather = HistoricalWeather.new(
        location: location,
        max_temperature: 25.0,
        min_temperature: 15.0,
        avg_temperature: 20.0,
        total_precipitation: 5.0,
        weather_code: 3,
        weather_date: Date.today
      )
      expect(historical_weather).to be_valid
    end
  end
end
