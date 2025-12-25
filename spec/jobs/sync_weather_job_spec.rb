require 'rails_helper'

RSpec.describe SyncWeatherJob, type: :job do
  let(:location) { create(:location, latitude: 37.7749, longitude: -122.4194) }
  let(:weather_service) { instance_double(WeatherService) }

  before do
    allow(WeatherService).to receive(:new).with(location).and_return(weather_service)
  end

  describe '#perform' do
    it 'syncs weather data for all locations' do
      expect_any_instance_of(described_class).to receive(:sync_current_weather).with(location)
      expect_any_instance_of(described_class).to receive(:sync_hourly_forecast).with(location)
      expect_any_instance_of(described_class).to receive(:sync_historical_weather).with(location)
      expect_any_instance_of(described_class).to receive(:sync_marine_weather).with(location)
      expect_any_instance_of(described_class).to receive(:sync_air_quality).with(location)
      expect_any_instance_of(described_class).to receive(:sync_flood_risk).with(location)
      expect_any_instance_of(described_class).to receive(:update_elevation).with(location)

      described_class.new.perform
    end
  end

  describe '#sync_current_weather' do
    let(:weather_data) do
      {
        temperature: 20.5,
        feels_like: 19.0,
        humidity: 65,
        wind_speed: 12.5,
        wind_direction: 180,
        wind_gust: 18.0,
        precipitation: 0.0,
        weather_code: 1,
        cloud_cover: 25,
        pressure: 1013.25,
        visibility: 10000
      }
    end

    before do
      allow(weather_service).to receive(:fetch_current_weather).and_return(weather_data)
    end

    it 'creates or updates weather metric' do
      expect {
        described_class.new.send(:sync_current_weather, location)
      }.to change(WeatherMetric, :count).by(1)
    end

    context 'when API returns nil' do
      before do
        allow(weather_service).to receive(:fetch_current_weather).and_return(nil)
      end

      it 'does not create weather metric' do
        expect {
          described_class.new.send(:sync_current_weather, location)
        }.not_to change(WeatherMetric, :count)
      end
    end
  end

  describe '#sync_hourly_forecast' do
    let(:forecast_data) do
      [
        {
          forecast_time: 1.hour.from_now,
          temperature: 21.0,
          humidity: 60,
          weather_code: 2,
          wind_speed: 13.0,
          precipitation_probability: 20,
          precipitation: 0.1
        }
      ]
    end

    before do
      allow(weather_service).to receive(:fetch_hourly_forecast).and_return(forecast_data)
    end

    it 'creates hourly forecasts' do
      expect {
        described_class.new.send(:sync_hourly_forecast, location)
      }.to change(HourlyForecast, :count).by(1)
    end
  end

  describe '#sync_historical_weather' do
    let(:historical_data) do
      [
        {
          weather_date: 1.day.ago.to_date,
          max_temperature: 25.0,
          min_temperature: 15.0,
          avg_temperature: 20.0,
          total_precipitation: 0.0,
          weather_code: 1
        }
      ]
    end

    before do
      allow(weather_service).to receive(:fetch_historical_weather).and_return(historical_data)
    end

    it 'creates historical weather records' do
      expect {
        described_class.new.send(:sync_historical_weather, location)
      }.to change(HistoricalWeather, :count).by(1)
    end
  end

  describe '#sync_marine_weather' do
    let(:marine_data) do
      {
        wave_height: 2.5,
        wave_period: 8.0,
        water_temperature: 18.5
      }
    end

    before do
      allow(weather_service).to receive(:fetch_marine_weather).and_return(marine_data)
    end

    it 'creates marine weather record' do
      expect {
        described_class.new.send(:sync_marine_weather, location)
      }.to change(MarineWeather, :count).by(1)
    end
  end

  describe '#sync_air_quality' do
    let(:air_quality_data) do
      {
        pm2_5: 15.5,
        pm10: 25.0,
        o3: 45.0,
        no2: 20.0,
        so2: 5.0,
        aqi_level: 2
      }
    end

    before do
      allow(weather_service).to receive(:fetch_air_quality).and_return(air_quality_data)
    end

    it 'creates air quality record' do
      expect {
        described_class.new.send(:sync_air_quality, location)
      }.to change(AirQuality, :count).by(1)
    end
  end

  describe '#sync_flood_risk' do
    let(:flood_data) do
      {
        flood_probability: 0.15,
        flood_severity: "low",
        flood_description: "Minimal flood risk"
      }
    end

    before do
      allow(weather_service).to receive(:fetch_flood_risk).and_return(flood_data)
    end

    it 'creates flood risk record' do
      expect {
        described_class.new.send(:sync_flood_risk, location)
      }.to change(FloodRisk, :count).by(1)
    end
  end

  describe '#update_elevation' do
    let(:elevation) { 100.5 }

    before do
      allow(weather_service).to receive(:fetch_elevation).and_return(elevation)
    end

    it 'updates location elevation' do
      described_class.new.send(:update_elevation, location)

      expect(location.reload.elevation).to eq(elevation)
    end

    context 'when API returns nil' do
      before do
        allow(weather_service).to receive(:fetch_elevation).and_return(nil)
      end

      it 'does not update elevation' do
        original_elevation = location.elevation
        described_class.new.send(:update_elevation, location)

        expect(location.reload.elevation).to eq(original_elevation)
      end
    end
  end

  describe 'error handling' do
    before do
      allow(weather_service).to receive(:fetch_current_weather).and_raise(StandardError.new("API Error"))
    end

    it 'logs errors and continues execution' do
      expect(Rails.logger).to receive(:error).at_least(:once)

      expect {
        described_class.new.send(:sync_current_weather, location)
      }.not_to raise_error
    end
  end
end
