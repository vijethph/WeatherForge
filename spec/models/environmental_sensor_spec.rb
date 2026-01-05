# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnvironmentalSensor do
  describe "associations" do
    it "optionally belongs to location" do
      sensor = create(:environmental_sensor)
      sensor.location = nil
      expect(sensor).to be_valid
    end

    it "has many environmental_readings" do
      sensor = create(:environmental_sensor)
      reading = create(:environmental_reading, environmental_sensor: sensor)
      expect(sensor.environmental_readings).to include(reading)
    end

    it "has many environmental_alerts" do
      sensor = create(:environmental_sensor)
      alert = create(:environmental_alert, environmental_sensor: sensor)
      expect(sensor.environmental_alerts).to include(alert)
    end
  end

  describe "validations" do
    it "validates presence of name" do
      sensor = build(:environmental_sensor, name: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:name]).to include("can't be blank")
    end

    it "validates presence of sensor_type" do
      sensor = build(:environmental_sensor, sensor_type: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:sensor_type]).to include("can't be blank")
    end

    it "validates presence of manufacturer" do
      sensor = build(:environmental_sensor, manufacturer: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:manufacturer]).to include("can't be blank")
    end

    it "validates presence of installation_date" do
      sensor = build(:environmental_sensor, installation_date: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:installation_date]).to include("can't be blank")
    end

    it "validates presence of latitude" do
      sensor = build(:environmental_sensor, location: nil, latitude: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:latitude]).to include("can't be blank")
    end

    it "validates presence of longitude" do
      sensor = build(:environmental_sensor, location: nil, longitude: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:longitude]).to include("can't be blank")
    end

    it "validates presence of status" do
      sensor = build(:environmental_sensor, status: nil)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:status]).to include("can't be blank")
    end

    it "validates sensor_type is in allowed values" do
      sensor = build(:environmental_sensor, sensor_type: "invalid_type")
      expect(sensor).not_to be_valid
      expect(sensor.errors[:sensor_type]).to be_present
    end

    it "validates status is in allowed values" do
      sensor = build(:environmental_sensor, status: "invalid_status")
      expect(sensor).not_to be_valid
      expect(sensor.errors[:status]).to be_present
    end

    it "validates latitude is between -90 and 90" do
      sensor = build(:environmental_sensor, latitude: 91)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:latitude]).to be_present
    end

    it "validates longitude is between -180 and 180" do
      sensor = build(:environmental_sensor, longitude: 181)
      expect(sensor).not_to be_valid
      expect(sensor.errors[:longitude]).to be_present
    end
  end

  describe "scopes" do
    let!(:active_sensor) { create(:environmental_sensor, :active) }
    let!(:inactive_sensor) { create(:environmental_sensor, :inactive) }
    let!(:air_quality_sensor) { create(:environmental_sensor, :air_quality) }
    let!(:temperature_sensor) { create(:environmental_sensor, :temperature) }

    describe ".active" do
      it "returns only active sensors" do
        expect(described_class.active).to include(active_sensor)
        expect(described_class.active).not_to include(inactive_sensor)
      end
    end

    describe ".by_type" do
      it "filters sensors by type" do
        expect(described_class.by_type("air_quality")).to include(air_quality_sensor)
        expect(described_class.by_type("air_quality")).not_to include(temperature_sensor)
      end
    end

    describe ".sorted" do
      it "orders sensors by name" do
        sensor_a = create(:environmental_sensor, name: "A Sensor")
        sensor_z = create(:environmental_sensor, name: "Z Sensor")

        expect(described_class.sorted.first).to eq(sensor_a)
        expect(described_class.sorted.last).to eq(sensor_z)
      end
    end
  end

  describe "instance methods" do
    let(:sensor) { create(:environmental_sensor) }

    describe "#latest_reading" do
      it "returns the most recent reading" do
        create(:environmental_reading, environmental_sensor: sensor, recorded_at: 2.hours.ago)
        latest_reading = create(:environmental_reading, environmental_sensor: sensor, recorded_at: 1.hour.ago)

        expect(sensor.latest_reading).to eq(latest_reading)
      end

      it "returns nil when no readings exist" do
        expect(sensor.latest_reading).to be_nil
      end
    end

    describe "#average_reading" do
      it "calculates average of readings in past N hours" do
        create(:environmental_reading, environmental_sensor: sensor, value: 10.0, recorded_at: 1.hour.ago)
        create(:environmental_reading, environmental_sensor: sensor, value: 20.0, recorded_at: 2.hours.ago)
        create(:environmental_reading, environmental_sensor: sensor, value: 30.0, recorded_at: 3.hours.ago)

        expect(sensor.average_reading(24)).to eq(20.0)
      end

      it "returns 0.0 when no readings in timeframe" do
        expect(sensor.average_reading(24)).to eq(0.0)
      end

      it "excludes readings older than specified hours" do
        create(:environmental_reading, environmental_sensor: sensor, value: 10.0, recorded_at: 1.hour.ago)
        create(:environmental_reading, environmental_sensor: sensor, value: 100.0, recorded_at: 48.hours.ago)

        expect(sensor.average_reading(24)).to eq(10.0)
      end
    end

    describe "#status_badge_class" do
      it "returns success class for active status" do
        sensor.status = "active"
        expect(sensor.status_badge_class).to eq("badge bg-success")
      end

      it "returns secondary class for inactive status" do
        sensor.status = "inactive"
        expect(sensor.status_badge_class).to eq("badge bg-secondary")
      end

      it "returns warning class for maintenance status" do
        sensor.status = "maintenance"
        expect(sensor.status_badge_class).to eq("badge bg-warning")
      end
    end

    describe "#active?" do
      it "returns true when status is active" do
        sensor.status = "active"
        expect(sensor).to be_active
      end

      it "returns false when status is not active" do
        sensor.status = "inactive"
        expect(sensor).not_to be_active
      end
    end
  end

  describe "callbacks" do
    context "when creating a sensor with a location" do
      let(:location) { create(:location, latitude: 37.7749, longitude: -122.4194) }
      let(:sensor) { build(:environmental_sensor, location: location, latitude: nil, longitude: nil) }

      it "sets latitude and longitude from location" do
        sensor.save
        expect(sensor.latitude).to eq(location.latitude)
        expect(sensor.longitude).to eq(location.longitude)
      end
    end
  end
end
