# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncEnvironmentalSensorsJob do
  let(:location) { create(:location, latitude: 37.7749, longitude: -122.4194) }
  let(:service) { instance_double(OpenAqService) }

  before do
    allow(OpenAqService).to receive(:new).and_return(service)
  end

  describe "#perform" do
    let(:sensors_data) do
      [
        {
          id: 123,
          name: "Test Sensor 1",
          provider: "OpenAQ",
          parameters: [
            { id: 1, name: "pm25", units: "µg/m³" },
            { id: 2, name: "pm10", units: "µg/m³" }
          ],
          coordinates: { latitude: 37.7750, longitude: -122.4195 },
          manufacturer: "Test Manufacturer",
          model_number: "TM-100"
        },
        {
          id: 456,
          name: "Test Sensor 2",
          provider: "OpenAQ",
          parameters: [
            { id: 3, name: "o3", units: "ppm" }
          ],
          coordinates: { latitude: 37.7760, longitude: -122.4200 },
          manufacturer: "Another Manufacturer",
          model_number: "AM-200"
        }
      ]
    end

    context "when syncing for all locations" do
      before do
        allow(service).to receive(:fetch_sensors_near_location).and_return(sensors_data)
      end

      it "syncs sensors for all locations" do
        expect(service).to receive(:fetch_sensors_near_location).with(
          lat: location.latitude,
          lon: location.longitude,
          radius: 50,
          limit: 100
        )

        described_class.perform_now
      end

      it "creates new sensors" do
        expect do
          described_class.perform_now
        end.to change(EnvironmentalSensor, :count).by(2)
      end

      it "stores OpenAQ metadata" do
        described_class.perform_now

        sensor = EnvironmentalSensor.last
        expect(sensor.metadata["openaq_id"]).to eq(456)
        expect(sensor.metadata["provider"]).to eq("OpenAQ")
      end

      it "returns sync statistics" do
        result = described_class.perform_now

        expect(result[:synced]).to eq(2)
        expect(result[:created]).to eq(2)
        expect(result[:updated]).to eq(0)
      end

      it "broadcasts sensors update" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:once)

        described_class.perform_now
      end
    end

    context "when syncing for specific location" do
      before do
        allow(service).to receive(:fetch_sensors_near_location).and_return(sensors_data)
      end

      it "syncs sensors for specified location only" do
        expect(service).to receive(:fetch_sensors_near_location).once

        described_class.perform_now(location_id: location.id)
      end

      it "uses custom radius" do
        expect(service).to receive(:fetch_sensors_near_location).with(
          lat: location.latitude,
          lon: location.longitude,
          radius: 25,
          limit: 100
        )

        described_class.perform_now(location_id: location.id, radius_km: 25)
      end
    end

    context "when updating existing sensors" do
      let!(:existing_sensor) do
        create(:environmental_sensor,
               location: location,
               latitude: 37.7750,
               longitude: -122.4195,
               metadata: { "openaq_id" => 123 })
      end

      before do
        allow(service).to receive(:fetch_sensors_near_location).and_return(sensors_data)
      end

      it "updates existing sensor instead of creating duplicate" do
        expect do
          described_class.perform_now(location_id: location.id)
        end.to change(EnvironmentalSensor, :count).by(1)
      end

      it "updates sensor attributes" do
        sensors_data[0][:name] = "Updated Sensor Name"

        described_class.perform_now(location_id: location.id)

        existing_sensor.reload
        expect(existing_sensor.name).to eq("Updated Sensor Name")
      end
    end

    context "when API returns no sensors" do
      before do
        allow(service).to receive(:fetch_sensors_near_location).and_return([])
      end

      it "does not create any sensors" do
        expect do
          described_class.perform_now(location_id: location.id)
        end.not_to change(EnvironmentalSensor, :count)
      end

      it "returns zero statistics" do
        result = described_class.perform_now(location_id: location.id)

        expect(result[:synced]).to eq(0)
        expect(result[:created]).to eq(0)
        expect(result[:updated]).to eq(0)
      end
    end

    context "when API call fails" do
      before do
        allow(service).to receive(:fetch_sensors_near_location).and_raise(StandardError, "API Error")
      end

      it "logs error and raises exception" do
        expect(Rails.logger).to receive(:error).with(/SyncEnvironmentalSensorsJob failed/)

        expect do
          described_class.perform_now(location_id: location.id)
        end.to raise_error(StandardError, "API Error")
      end
    end

    context "when sensor has no priority parameters" do
      let(:sensors_without_priority) do
        [
          {
            id: 789,
            name: "Non-Priority Sensor",
            provider: "OpenAQ",
            parameters: [
              { id: 4, name: "humidity", units: "%" }
            ],
            coordinates: { latitude: 37.7770, longitude: -122.4210 }
          }
        ]
      end

      before do
        allow(service).to receive(:fetch_sensors_near_location).and_return(sensors_without_priority)
      end

      it "skips sensors without priority parameters" do
        expect do
          described_class.perform_now(location_id: location.id)
        end.not_to change(EnvironmentalSensor, :count)
      end
    end
  end
end
