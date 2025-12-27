require 'rails_helper'

RSpec.describe AirQuality, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      location = create(:location)
      air_quality = AirQuality.new(
        location: location,
        pm2_5: 12.5,
        pm10: 25.0,
        o3: 45.0,
        no2: 30.0,
        so2: 15.0,
        aqi_level: 2,
        recorded_at: Time.current
      )
      expect(air_quality).to be_valid
    end
  end
end
