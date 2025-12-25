require 'rails_helper'

RSpec.describe FloodRisk, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      location = create(:location)
      flood_risk = FloodRisk.new(
        location: location,
        flood_probability: 0.25,
        flood_severity: 'moderate',
        flood_description: 'Moderate flood risk',
        recorded_at: Time.current
      )
      expect(flood_risk).to be_valid
    end
  end
end
