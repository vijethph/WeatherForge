require 'rails_helper'

RSpec.describe WeatherService do
  let(:location) { create(:location, latitude: 37.7749, longitude: -122.4194, timezone: "America/Los_Angeles") }
  let(:service) { described_class.new(location) }

  describe '#fetch_current_weather' do
    context 'with successful API response' do
      before do
        api_response = {
          "current" => {
            "temperature_2m" => 20.5,
            "relative_humidity_2m" => 65,
            "weather_code" => 1,
            "wind_speed_10m" => 12.5,
            "wind_direction_10m" => 180,
            "wind_gusts_10m" => 18.0,
            "precipitation" => 0.0,
            "cloud_cover" => 25,
            "pressure_msl" => 1013.25,
            "visibility" => 10000,
            "apparent_temperature" => 19.0
          }
        }

        response = double("HTTP Response")
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:[]).with("current").and_return(api_response["current"])
        allow(HTTParty).to receive(:get).and_return(response)
      end

      it 'returns parsed current weather data' do
        result = service.fetch_current_weather

        expect(result).to be_a(Hash)
        expect(result[:temperature]).to eq(20.5)
        expect(result[:humidity]).to eq(65)
        expect(result[:weather_code]).to eq(1)
        expect(result[:wind_speed]).to eq(12.5)
      end
    end

    context 'with failed API response' do
      before do
        response = double("HTTP Response", success?: false)
        allow(HTTParty).to receive(:get).and_return(response)
      end

      it 'returns nil' do
        expect(service.fetch_current_weather).to be_nil
      end
    end

    context 'with API exception' do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new("Network error"))
      end

      it 'logs error and returns nil' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        expect(service.fetch_current_weather).to be_nil
      end
    end
  end

  describe '#fetch_hourly_forecast' do
    it 'returns array when successful' do
      expect(service).to receive(:fetch_hourly_forecast).and_return([
        {
          forecast_time: Time.current,
          temperature: 20.5,
          humidity: 65,
          weather_code: 1,
          wind_speed: 12.5,
          precipitation_probability: 10,
          precipitation: 0.0
        }
      ])

      result = service.fetch_hourly_forecast
      expect(result).to be_an(Array)
      expect(result.first[:temperature]).to eq(20.5)
    end
  end

  describe '#fetch_historical_weather' do
    it 'returns array when successful' do
      expect(service).to receive(:fetch_historical_weather).and_return([
        {
          weather_date: Date.today,
          max_temperature: 25.0,
          min_temperature: 15.0,
          avg_temperature: 20.0,
          total_precipitation: 0.0,
          weather_code: 1
        }
      ])

      result = service.fetch_historical_weather
      expect(result).to be_an(Array)
      expect(result.first[:max_temperature]).to eq(25.0)
    end
  end

  describe '#fetch_marine_weather' do
    it 'returns hash when successful' do
      expect(service).to receive(:fetch_marine_weather).and_return({
        wave_height: 2.5,
        wave_period: 8.0,
        water_temperature: 18.5
      })

      result = service.fetch_marine_weather
      expect(result[:wave_height]).to eq(2.5)
    end
  end

  describe '#fetch_air_quality' do
    it 'returns hash with AQI level when successful' do
      expect(service).to receive(:fetch_air_quality).and_return({
        pm2_5: 15.5,
        pm10: 25.0,
        o3: 45.0,
        no2: 20.0,
        so2: 5.0,
        aqi_level: 2
      })

      result = service.fetch_air_quality
      expect(result[:pm2_5]).to eq(15.5)
      expect(result[:aqi_level]).to eq(2)
    end
  end

  describe '#fetch_flood_risk' do
    it 'returns hash when successful' do
      expect(service).to receive(:fetch_flood_risk).and_return({
        flood_probability: 0.15,
        flood_severity: "low",
        flood_description: "Minimal flood risk"
      })

      result = service.fetch_flood_risk
      expect(result[:flood_severity]).to eq("low")
    end
  end

  describe '#fetch_elevation' do
    it 'returns elevation when successful' do
      expect(service).to receive(:fetch_elevation).and_return(100.5)

      result = service.fetch_elevation
      expect(result).to eq(100.5)
    end
  end

  describe '.search_locations' do
    it 'returns array of locations when successful' do
      expect(described_class).to receive(:search_locations).with("San Francisco").and_return([
        {
          name: "San Francisco",
          latitude: 37.7749,
          longitude: -122.4194,
          country: "United States",
          timezone: "America/Los_Angeles"
        }
      ])

      result = described_class.search_locations("San Francisco")
      expect(result).to be_an(Array)
      expect(result.first[:name]).to eq("San Francisco")
    end

    it 'returns empty array when no results' do
      expect(described_class).to receive(:search_locations).with("NonexistentCity").and_return([])

      result = described_class.search_locations("NonexistentCity")
      expect(result).to eq([])
    end
  end
end
