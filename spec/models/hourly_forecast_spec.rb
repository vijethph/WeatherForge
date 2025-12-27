require 'rails_helper'

RSpec.describe HourlyForecast, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      location = create(:location)
      hourly_forecast = HourlyForecast.new(
        location: location,
        temperature: 20.0,
        humidity: 65,
        weather_code: 2,
        wind_speed: 12.5,
        precipitation_probability: 30,
        precipitation: 0.5,
        forecast_time: Time.current + 1.hour
      )
      expect(hourly_forecast).to be_valid
    end
  end
end
