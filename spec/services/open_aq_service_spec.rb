# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpenAqService do
  let(:api_key) { "test_api_key_12345" }
  let(:service) { described_class.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("OPENAQ_API_KEY").and_return(api_key)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("OPENAQ_BASE_URL", anything).and_return("https://api.openaq.org/v3")
  end

  describe "#initialize" do
    context "with valid API key" do
      it "initializes successfully" do
        expect(service.api_key).to eq(api_key)
      end
    end

    context "without API key" do
      before { allow(ENV).to receive(:[]).with("OPENAQ_API_KEY").and_return(nil) }

      it "raises ConfigurationError" do
        expect { service }.to raise_error(OpenAqService::ConfigurationError, /OPENAQ_API_KEY/)
      end
    end

    context "with placeholder API key" do
      before { allow(ENV).to receive(:[]).with("OPENAQ_API_KEY").and_return("your_openaq_api_key_here") }

      it "logs warning but initializes" do
        expect(Rails.logger).to receive(:warn).with(/placeholder/)
        expect { service }.not_to raise_error
      end
    end
  end

  describe "#fetch_sensors_near_location" do
    let(:mock_response) do
      {
        "results" => [
          {
            "id" => 123,
            "name" => "SF Downtown Station",
            "locality" => { "name" => "San Francisco" },
            "country" => { "name" => "United States", "code" => "US" },
            "coordinates" => { "latitude" => 37.7749, "longitude" => -122.4194 },
            "parameters" => [
              { "parameter" => "pm25" },
              { "parameter" => "pm10" },
              { "parameter" => "o3" }
            ],
            "provider" => { "name" => "PurpleAir" },
            "isMobile" => false,
            "isActive" => true,
            "firstUpdated" => "2020-01-01T00:00:00Z",
            "lastUpdated" => "2024-01-04T12:00:00Z",
            "measurements" => 150_000
          }
        ]
      }
    end

    before do
      allow_any_instance_of(described_class).to receive(:make_request).and_return(mock_response)
    end

    it "fetches sensors near location" do
      sensors = service.fetch_sensors_near_location(lat: 37.7749, lon: -122.4194, radius: 25)

      expect(sensors).to be_an(Array)
      expect(sensors.length).to eq(1)
      expect(sensors.first[:openaq_id]).to eq(123)
      expect(sensors.first[:name]).to eq("SF Downtown Station")
      expect(sensors.first[:country_code]).to eq("US")
      expect(sensors.first[:latitude]).to eq(37.7749)
      expect(sensors.first[:longitude]).to eq(-122.4194)
    end

    it "includes extracted parameters" do
      sensors = service.fetch_sensors_near_location(lat: 37.7749, lon: -122.4194)
      expect(sensors.first[:parameters]).to contain_exactly("pm25", "pm10", "o3")
    end

    it "determines sensor type correctly" do
      sensors = service.fetch_sensors_near_location(lat: 37.7749, lon: -122.4194)
      expect(sensors.first[:sensor_type]).to eq("air_quality")
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns empty array" do
        sensors = service.fetch_sensors_near_location(lat: 37.7749, lon: -122.4194)
        expect(sensors).to eq([])
      end
    end

    context "with network error" do
      before do
        allow_any_instance_of(described_class).to receive(:make_request).and_raise(SocketError)
      end

      it "logs error and returns empty array" do
        expect(Rails.logger).to receive(:error).with(/fetch_sensors_near_location/)
        sensors = service.fetch_sensors_near_location(lat: 37.7749, lon: -122.4194)
        expect(sensors).to eq([])
      end
    end
  end

  describe "#fetch_latest_measurements" do
    let(:mock_response) do
      {
        "results" => [
          {
            "location" => 123,
            "date" => "2024-01-04T12:00:00Z",
            "parameters" => [
              { "parameter" => "pm25", "value" => 12.5, "unit" => "µg/m³", "lastUpdated" => "2024-01-04T12:00:00Z" },
              { "parameter" => "pm10", "value" => 25.3, "unit" => "µg/m³", "lastUpdated" => "2024-01-04T12:00:00Z" }
            ]
          }
        ]
      }
    end

    before do
      allow_any_instance_of(described_class).to receive(:make_request).and_return(mock_response)
    end

    it "fetches latest measurements for location" do
      measurements = service.fetch_latest_measurements(location_id: 123)

      expect(measurements).to be_a(Hash)
      expect(measurements[:location_id]).to eq(123)
      expect(measurements[:parameters]).to be_an(Array)
      expect(measurements[:parameters].length).to eq(2)
    end

    it "parses parameter measurements correctly" do
      measurements = service.fetch_latest_measurements(location_id: 123)
      pm25 = measurements[:parameters].first

      expect(pm25[:parameter]).to eq("pm25")
      expect(pm25[:value]).to eq(12.5)
      expect(pm25[:unit]).to eq("µg/m³")
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns nil" do
        measurements = service.fetch_latest_measurements(location_id: 123)
        expect(measurements).to be_nil
      end
    end
  end

  describe "#fetch_measurements_by_time" do
    let(:mock_response) do
      {
        "results" => [
          {
            "location" => 123,
            "sensors_id" => 456,
            "parameter" => "pm25",
            "value" => 12.5,
            "unit" => "µg/m³",
            "date" => "2024-01-04T12:00:00Z",
            "coordinates" => { "latitude" => 37.7749, "longitude" => -122.4194 }
          },
          {
            "location" => 123,
            "sensors_id" => 456,
            "parameter" => "pm10",
            "value" => 25.3,
            "unit" => "µg/m³",
            "date" => "2024-01-04T12:00:00Z",
            "coordinates" => { "latitude" => 37.7749, "longitude" => -122.4194 }
          }
        ]
      }
    end

    before do
      allow_any_instance_of(described_class).to receive(:make_request).and_return(mock_response)
    end

    it "fetches measurements by time range" do
      date_from = 1.day.ago
      date_to = Time.current
      measurements = service.fetch_measurements_by_time(
        location_id: 123,
        date_from: date_from,
        date_to: date_to
      )

      expect(measurements).to be_an(Array)
      expect(measurements.length).to eq(2)
      expect(measurements.first[:parameter]).to eq("pm25")
      expect(measurements.last[:parameter]).to eq("pm10")
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns empty array" do
        measurements = service.fetch_measurements_by_time(
          location_id: 123,
          date_from: 1.day.ago,
          date_to: Time.current
        )
        expect(measurements).to eq([])
      end
    end
  end

  describe "#search_locations" do
    let(:mock_response) do
      {
        "results" => [
          {
            "id" => 123,
            "name" => "SF Station",
            "locality" => { "name" => "San Francisco" },
            "country" => { "name" => "United States", "code" => "US" },
            "coordinates" => { "latitude" => 37.7749, "longitude" => -122.4194 },
            "parameters" => [ { "parameter" => "pm25" } ]
          }
        ]
      }
    end

    before do
      allow_any_instance_of(described_class).to receive(:make_request).and_return(mock_response)
    end

    it "searches locations by country" do
      locations = service.search_locations(country: "US")

      expect(locations).to be_an(Array)
      expect(locations.first[:country_code]).to eq("US")
    end

    it "searches locations by city" do
      locations = service.search_locations(city: "San Francisco")

      expect(locations).to be_an(Array)
      expect(locations.first[:locality]).to eq("San Francisco")
    end

    it "searches locations by name" do
      locations = service.search_locations(name: "SF Station")

      expect(locations).to be_an(Array)
      expect(locations.first[:name]).to eq("SF Station")
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns empty array" do
        locations = service.search_locations(country: "US")
        expect(locations).to eq([])
      end
    end
  end

  describe "#fetch_available_parameters" do
    let(:mock_response) do
      {
        "results" => [
          {
            "id" => 1,
            "name" => "pm25",
            "displayName" => "PM2.5",
            "description" => "Particulate matter less than 2.5 micrometers",
            "units" => "µg/m³"
          }
        ]
      }
    end

    before do
      allow_any_instance_of(described_class).to receive(:make_request).and_return(mock_response)
    end

    it "fetches available parameters" do
      params = service.fetch_available_parameters

      expect(params).to be_an(Array)
      expect(params.first[:name]).to eq("pm25")
      expect(params.first[:display_name]).to eq("PM2.5")
      expect(params.first[:units]).to eq("µg/m³")
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns empty array" do
        params = service.fetch_available_parameters
        expect(params).to eq([])
      end
    end
  end

  describe "#fetch_countries" do
    let(:mock_response) do
      {
        "results" => [
          {
            "code" => "US",
            "name" => "United States",
            "locations" => 1500,
            "measurements" => 50_000_000
          }
        ]
      }
    end

    before do
      allow_any_instance_of(described_class).to receive(:make_request).and_return(mock_response)
    end

    it "fetches countries" do
      countries = service.fetch_countries

      expect(countries).to be_an(Array)
      expect(countries.first[:code]).to eq("US")
      expect(countries.first[:name]).to eq("United States")
      expect(countries.first[:locations_count]).to eq(1500)
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns empty array" do
        countries = service.fetch_countries
        expect(countries).to eq([])
      end
    end
  end

  describe "#connection_healthy?" do
    context "with successful API response" do
      before do
        allow_any_instance_of(described_class).to receive(:make_request).and_return({ "results" => [] })
      end

      it "returns true" do
        expect(service.connection_healthy?).to be true
      end
    end

    context "with API error" do
      before { allow_any_instance_of(described_class).to receive(:make_request).and_return(nil) }

      it "returns false" do
        expect(service.connection_healthy?).to be false
      end
    end

    context "with network error" do
      before do
        allow_any_instance_of(described_class).to receive(:make_request).and_raise(SocketError)
      end

      it "returns false" do
        expect(service.connection_healthy?).to be false
      end
    end
  end

  describe "private methods" do
    describe "#determine_sensor_type" do
      it "identifies air_quality sensors" do
        location = { "parameters" => [ { "parameter" => "pm25" }, { "parameter" => "o3" } ] }
        sensor_type = service.send(:determine_sensor_type, location)
        expect(sensor_type).to eq("air_quality")
      end

      it "identifies temperature sensors" do
        location = { "parameters" => [ { "parameter" => "temperature" } ] }
        sensor_type = service.send(:determine_sensor_type, location)
        expect(sensor_type).to eq("temperature")
      end

      it "defaults to air_quality" do
        location = { "parameters" => [] }
        sensor_type = service.send(:determine_sensor_type, location)
        expect(sensor_type).to eq("air_quality")
      end
    end

    describe "#parse_datetime" do
      it "parses valid ISO8601 datetime" do
        datetime = service.send(:parse_datetime, "2024-01-04T12:00:00Z")
        expect(datetime).to be_a(Time)
      end

      it "returns nil for blank string" do
        datetime = service.send(:parse_datetime, "")
        expect(datetime).to be_nil
      end

      it "returns nil for invalid datetime" do
        datetime = service.send(:parse_datetime, "invalid")
        expect(datetime).to be_nil
      end
    end
  end
end
