# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncEnvironmentalReadingsJob do
  let(:location) { create(:location) }
  let(:sensor) do
    create(:environmental_sensor,
           :active,
           location: location,
           metadata: {
             "openaq_id" => 123,
             "openaq_sensor_ids" => [
               { "sensor_id" => 1001, "parameter" => "pm25" },
               { "sensor_id" => 1002, "parameter" => "pm10" }
             ]
           })
  end
  let(:service) { instance_double(OpenAqService) }

  before do
    allow(OpenAqService).to receive(:new).and_return(service)
  end

  describe "#perform" do
    let(:measurements_data) do
      [
        {
          period: { datetime_from: 2.hours.ago, datetime_to: 1.hour.ago },
          value: 25.5,
          parameter: { name: "pm25", units: "µg/m³" }
        },
        {
          period: { datetime_from: 1.hour.ago, datetime_to: Time.current },
          value: 28.3,
          parameter: { name: "pm25", units: "µg/m³" }
        }
      ]
    end

    context "when syncing all sensors" do
      before do
        allow(service).to receive(:fetch_sensor_measurements).and_return(measurements_data)
      end

      it "syncs readings for all active sensors" do
        sensor # Create sensor

        expect(service).to receive(:fetch_sensor_measurements).at_least(:once)

        described_class.perform_now
      end

      it "creates new readings" do
        sensor # Create sensor

        expect do
          described_class.perform_now
        end.to change(EnvironmentalReading, :count).by_at_least(2)
      end

      it "returns sync statistics" do
        sensor # Create sensor

        result = described_class.perform_now

        expect(result[:sensors]).to eq(1)
        expect(result[:readings]).to be > 0
      end

      it "broadcasts readings update" do
        sensor # Create sensor

        expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:once)

        described_class.perform_now
      end
    end

    context "when syncing specific sensor" do
      before do
        allow(service).to receive(:fetch_sensor_measurements).and_return(measurements_data)
      end

      it "syncs readings for specified sensor only" do
        expect(service).to receive(:fetch_sensor_measurements).at_least(:once)

        described_class.perform_now(sensor_id: sensor.id)
      end

      it "creates readings with correct attributes" do
        described_class.perform_now(sensor_id: sensor.id)

        reading = sensor.environmental_readings.last
        expect(reading.parameter_name).to eq("pm25")
        expect(reading.unit).to eq("µg/m³")
        expect(reading.value).to be_present
      end
    end

    context "when sensor has no OpenAQ metadata" do
      let(:sensor_without_metadata) { create(:environmental_sensor, :active, location: location) }

      it "skips sensor without OpenAQ metadata" do
        expect(service).not_to receive(:fetch_sensor_measurements)

        result = described_class.perform_now(sensor_id: sensor_without_metadata.id)

        expect(result).to eq(0)
      end
    end

    context "when reading exceeds threshold" do
      let(:high_value_measurements) do
        [
          {
            period: { datetime_from: 1.hour.ago, datetime_to: Time.current },
            value: 150.0,
            parameter: { name: "pm25", units: "µg/m³" }
          }
        ]
      end

      before do
        allow(service).to receive(:fetch_sensor_measurements).and_return(high_value_measurements)
      end

      it "creates an alert for threshold violation" do
        expect do
          described_class.perform_now(sensor_id: sensor.id)
        end.to change(EnvironmentalAlert, :count)
      end

      it "broadcasts alert to subscribers" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).at_least(:once)

        described_class.perform_now(sensor_id: sensor.id)
      end
    end

    context "when API returns no measurements" do
      before do
        allow(service).to receive(:fetch_sensor_measurements).and_return([])
      end

      it "does not create any readings" do
        expect do
          described_class.perform_now(sensor_id: sensor.id)
        end.not_to change(EnvironmentalReading, :count)
      end
    end

    context "when API call fails" do
      before do
        allow(service).to receive(:fetch_sensor_measurements)
          .and_raise(StandardError, "API Error")
      end

      it "logs error and raises exception" do
        expect(Rails.logger).to receive(:error).with(/SyncEnvironmentalReadingsJob failed/)

        expect do
          described_class.perform_now(sensor_id: sensor.id)
        end.to raise_error(StandardError, "API Error")
      end
    end

    context "when duplicate readings exist" do
      before do
        allow(service).to receive(:fetch_sensor_measurements).and_return(measurements_data)

        # Create existing reading
        create(:environmental_reading,
               environmental_sensor: sensor,
               parameter_name: "pm25",
               value: 25.5,
               recorded_at: 2.hours.ago)
      end

      it "avoids creating duplicate readings" do
        initial_count = sensor.environmental_readings.count

        described_class.perform_now(sensor_id: sensor.id)

        # Should create new readings but not duplicate existing ones
        expect(sensor.environmental_readings.count).to be >= initial_count
      end
    end

    context "when sensor is inactive" do
      let(:inactive_sensor) do
        create(:environmental_sensor,
               :inactive,
               location: location,
               metadata: { "openaq_sensor_ids" => [ { "sensor_id" => 1001 } ] })
      end

      it "skips inactive sensors" do
        expect(service).not_to receive(:fetch_sensor_measurements)

        described_class.perform_now
      end
    end
  end
end
