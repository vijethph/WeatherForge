require 'rails_helper'

RSpec.describe MarineWeather, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      location = create(:location)
      marine_weather = MarineWeather.new(
        location: location,
        wave_height: 2.5,
        wave_period: 8.0,
        water_temperature: 18.5,
        recorded_at: Time.current
      )
      expect(marine_weather).to be_valid
    end
  end
end
