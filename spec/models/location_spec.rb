require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'validations' do
    subject { build(:location) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:latitude) }
    it { is_expected.to validate_presence_of(:longitude) }
    it { is_expected.to validate_numericality_of(:latitude).is_greater_than_or_equal_to(-90).is_less_than_or_equal_to(90) }
    it { is_expected.to validate_numericality_of(:longitude).is_greater_than_or_equal_to(-180).is_less_than_or_equal_to(180) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:weather_metrics).dependent(:destroy) }
    it { is_expected.to have_many(:hourly_forecasts).dependent(:destroy) }
    it { is_expected.to have_many(:historical_weathers).dependent(:destroy) }
    it { is_expected.to have_many(:marine_weathers).dependent(:destroy) }
    it { is_expected.to have_many(:air_qualities).dependent(:destroy) }
    it { is_expected.to have_many(:flood_risks).dependent(:destroy) }
  end

  describe 'scopes' do
    describe '.sorted' do
      it 'returns locations ordered by name' do
        create(:location, name: "Zurich")
        create(:location, name: "Amsterdam")
        create(:location, name: "Berlin")

        expect(Location.sorted.pluck(:name)).to eq(%w[Amsterdam Berlin Zurich])
      end
    end
  end

  describe '#latest_weather' do
    let(:location) { create(:location) }

    it 'returns the most recent weather metric' do
      metric1 = create(:weather_metric, location: location, recorded_at: 2.hours.ago)
      metric2 = create(:weather_metric, location: location, recorded_at: 1.hour.ago)

      expect(location.latest_weather).to eq(metric2)
    end

    it 'returns nil when no weather metrics exist' do
      expect(location.latest_weather).to be_nil
    end
  end

  describe '#weather_metrics_24h' do
    let(:location) { create(:location) }

    it 'returns metrics from last 24 hours' do
      create(:weather_metric, location: location, recorded_at: 25.hours.ago)
      recent = create(:weather_metric, location: location, recorded_at: 1.hour.ago)

      expect(location.weather_metrics_24h).to include(recent)
      expect(location.weather_metrics_24h.count).to eq(1)
    end
  end

  describe '#weather_metrics_7d' do
    let(:location) { create(:location) }

    it 'returns metrics from last 7 days' do
      create(:weather_metric, location: location, recorded_at: 8.days.ago)
      recent = create(:weather_metric, location: location, recorded_at: 1.day.ago)

      expect(location.weather_metrics_7d).to include(recent)
      expect(location.weather_metrics_7d.count).to eq(1)
    end
  end

  describe '#hourly_forecast_24h' do
    let(:location) { create(:location) }

    it 'returns forecasts for next 24 hours' do
      create(:hourly_forecast, location: location, forecast_time: 25.hours.from_now)
      recent = create(:hourly_forecast, location: location, forecast_time: 2.hours.from_now)

      expect(location.hourly_forecast_24h).to include(recent)
      expect(location.hourly_forecast_24h.count).to eq(1)
    end
  end

  describe '#historical_weather_10d' do
    let(:location) { create(:location) }

    it 'returns last 10 days of historical weather' do
      create(:historical_weather, location: location, weather_date: 11.days.ago.to_date)
      recent = create(:historical_weather, location: location, weather_date: 1.day.ago.to_date)

      expect(location.historical_weather_10d).to include(recent)
      expect(location.historical_weather_10d.count).to eq(1)
    end
  end

  describe '#latest_marine_weather' do
    let(:location) { create(:location) }

    it 'returns the most recent marine weather' do
      create(:marine_weather, location: location, recorded_at: 2.hours.ago)
      latest = create(:marine_weather, location: location, recorded_at: 1.hour.ago)

      expect(location.latest_marine_weather).to eq(latest)
    end
  end

  describe '#latest_air_quality' do
    let(:location) { create(:location) }

    it 'returns the most recent air quality reading' do
      create(:air_quality, location: location, recorded_at: 2.hours.ago)
      latest = create(:air_quality, location: location, recorded_at: 1.hour.ago)

      expect(location.latest_air_quality).to eq(latest)
    end
  end

  describe '#latest_flood_risk' do
    let(:location) { create(:location) }

    it 'returns the most recent flood risk assessment' do
      create(:flood_risk, location: location, recorded_at: 2.hours.ago)
      latest = create(:flood_risk, location: location, recorded_at: 1.hour.ago)

      expect(location.latest_flood_risk).to eq(latest)
    end
  end

  describe '#aqi_level_name' do
    let(:location) { create(:location) }

    context 'when air quality data exists' do
      it 'returns the AQI level name' do
        create(:air_quality, location: location, aqi_level: 1)

        expect(location.aqi_level_name).to eq("Good")
      end
    end

    context 'when no air quality data exists' do
      it 'returns "N/A"' do
        expect(location.aqi_level_name).to eq("N/A")
      end
    end
  end
end
