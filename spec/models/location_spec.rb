require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'validations' do
    subject { build(:location) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:latitude) }
    it { is_expected.to validate_presence_of(:longitude) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:weather_metrics).dependent(:destroy) }
  end

  describe '#latest_weather' do
    let(:location) { create(:location) }

    it 'returns the most recent weather metric' do
      metric1 = create(:weather_metric, location: location, recorded_at: 1.hour.ago)
      metric2 = create(:weather_metric, location: location, recorded_at: Time.current)

      expect(location.latest_weather).to eq(metric2)
    end
  end
end
