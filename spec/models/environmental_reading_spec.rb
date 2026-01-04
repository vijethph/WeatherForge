# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnvironmentalReading do
  describe "associations" do
    it "belongs to environmental_sensor" do
      reading = create(:environmental_reading)
      expect(reading.environmental_sensor).to be_present
    end
  end

  describe "validations" do
    it "validates presence of value" do
      reading = build(:environmental_reading, value: nil)
      expect(reading).not_to be_valid
      expect(reading.errors[:value]).to include("can't be blank")
    end

    it "validates presence of unit" do
      reading = build(:environmental_reading, unit: nil)
      expect(reading).not_to be_valid
      expect(reading.errors[:unit]).to include("can't be blank")
    end

    it "validates presence of recorded_at" do
      reading = build(:environmental_reading, recorded_at: nil)
      expect(reading).not_to be_valid
      expect(reading.errors[:recorded_at]).to include("can't be blank")
    end

    it "validates value is numeric" do
      reading = build(:environmental_reading, value: "not_a_number")
      expect(reading).not_to be_valid
      expect(reading.errors[:value]).to be_present
    end
  end

  describe "scopes" do
    let(:sensor) { create(:environmental_sensor) }
    let!(:recent_reading) { create(:environmental_reading, :recent, environmental_sensor: sensor) }
    let!(:old_reading) { create(:environmental_reading, :old, environmental_sensor: sensor) }

    describe ".recent" do
      it "orders readings by recorded_at descending" do
        expect(described_class.recent.first).to eq(recent_reading)
      end

      it "limits results to 100" do
        create_list(:environmental_reading, 150, environmental_sensor: sensor)
        expect(described_class.recent.count).to eq(100)
      end
    end

    describe ".for_sensor" do
      let(:other_sensor) { create(:environmental_sensor) }
      let!(:other_reading) { create(:environmental_reading, environmental_sensor: other_sensor) }

      it "returns readings for specific sensor" do
        expect(described_class.for_sensor(sensor)).to include(recent_reading, old_reading)
        expect(described_class.for_sensor(sensor)).not_to include(other_reading)
      end
    end

    describe ".in_timerange" do
      it "returns readings within specified time range" do
        start_time = 10.hours.ago
        end_time = Time.current

        expect(described_class.in_timerange(start_time, end_time)).to include(recent_reading)
        expect(described_class.in_timerange(start_time, end_time)).not_to include(old_reading)
      end
    end

    describe ".exceeding" do
      let!(:high_reading) { create(:environmental_reading, :high_value, environmental_sensor: sensor) }
      let!(:low_reading) { create(:environmental_reading, value: 5.0, environmental_sensor: sensor) }

      it "returns readings above threshold" do
        expect(described_class.exceeding(50.0)).to include(high_reading)
        expect(described_class.exceeding(50.0)).not_to include(low_reading)
      end
    end
  end

  describe "class methods" do
    let(:sensor) { create(:environmental_sensor) }

    describe ".for_chartkick" do
      it "returns data formatted for Chartkick charts" do
        reading1 = create(:environmental_reading, environmental_sensor: sensor, value: 10.0, recorded_at: 2.hours.ago)
        reading2 = create(:environmental_reading, environmental_sensor: sensor, value: 20.0, recorded_at: 1.hour.ago)

        chart_data = described_class.for_chartkick(sensor, 24)

        expect(chart_data).to be_an(Array)
        expect(chart_data.length).to eq(2)
        expect(chart_data.first).to eq([ reading1.recorded_at, 10.0 ])
        expect(chart_data.last).to eq([ reading2.recorded_at, 20.0 ])
      end

      it "orders data by recorded_at ascending" do
        create(:environmental_reading, environmental_sensor: sensor, value: 20.0, recorded_at: 1.hour.ago)
        create(:environmental_reading, environmental_sensor: sensor, value: 10.0, recorded_at: 2.hours.ago)

        chart_data = described_class.for_chartkick(sensor, 24)

        expect(chart_data.first[1]).to eq(10.0)
        expect(chart_data.last[1]).to eq(20.0)
      end

      it "filters by time range" do
        create(:environmental_reading, environmental_sensor: sensor, value: 10.0, recorded_at: 1.hour.ago)
        create(:environmental_reading, environmental_sensor: sensor, value: 100.0, recorded_at: 48.hours.ago)

        chart_data = described_class.for_chartkick(sensor, 24)

        expect(chart_data.length).to eq(1)
        expect(chart_data.first[1]).to eq(10.0)
      end
    end
  end

  describe "#health_level" do
    context "with air_quality sensor" do
      let(:sensor) { create(:environmental_sensor, sensor_type: "air_quality") }

      it "returns Good for AQI 0-50" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 25)
        expect(reading.health_level).to eq("Good")
      end

      it "returns Moderate for AQI 51-100" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 75)
        expect(reading.health_level).to eq("Moderate")
      end

      it "returns Unhealthy for Sensitive Groups for AQI 101-150" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 125)
        expect(reading.health_level).to eq("Unhealthy for Sensitive Groups")
      end

      it "returns Unhealthy for AQI 151-200" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 175)
        expect(reading.health_level).to eq("Unhealthy")
      end

      it "returns Very Unhealthy for AQI 201-300" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 250)
        expect(reading.health_level).to eq("Very Unhealthy")
      end

      it "returns Hazardous for AQI > 300" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 350)
        expect(reading.health_level).to eq("Hazardous")
      end
    end

    context "with pm25 sensor" do
      let(:sensor) { create(:environmental_sensor, sensor_type: "pm25") }

      it "returns Good for PM2.5 0-12" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 10)
        expect(reading.health_level).to eq("Good")
      end

      it "returns Moderate for PM2.5 13-35" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 25)
        expect(reading.health_level).to eq("Moderate")
      end

      it "returns Unhealthy for Sensitive Groups for PM2.5 36-55" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 45)
        expect(reading.health_level).to eq("Unhealthy for Sensitive Groups")
      end

      it "returns Very Unhealthy for PM2.5 > 150" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 200)
        expect(reading.health_level).to eq("Very Unhealthy")
      end
    end

    context "with other sensor types" do
      let(:sensor) { create(:environmental_sensor, sensor_type: "temperature") }

      it "returns Unknown" do
        reading = create(:environmental_reading, environmental_sensor: sensor, value: 25)
        expect(reading.health_level).to eq("Unknown")
      end
    end
  end

  describe "#health_level_color" do
    let(:sensor) { create(:environmental_sensor, sensor_type: "air_quality") }

    it "returns success for Good" do
      reading = create(:environmental_reading, environmental_sensor: sensor, value: 25)
      allow(reading).to receive(:health_level).and_return("Good")
      expect(reading.health_level_color).to eq("success")
    end

    it "returns danger for Hazardous" do
      reading = create(:environmental_reading, environmental_sensor: sensor, value: 400)
      allow(reading).to receive(:health_level).and_return("Hazardous")
      expect(reading.health_level_color).to eq("danger")
    end
  end

  describe "#exceeds_threshold?" do
    it "returns true when PM2.5 exceeds 35.4" do
      sensor = create(:environmental_sensor, sensor_type: "pm25")
      reading = create(:environmental_reading, environmental_sensor: sensor, value: 40)
      expect(reading).to be_exceeds_threshold
    end

    it "returns false when PM2.5 is below 35.4" do
      sensor = create(:environmental_sensor, sensor_type: "pm25")
      reading = create(:environmental_reading, environmental_sensor: sensor, value: 30)
      expect(reading).not_to be_exceeds_threshold
    end

    it "returns false for sensor types without thresholds" do
      sensor = create(:environmental_sensor, sensor_type: "humidity")
      reading = create(:environmental_reading, environmental_sensor: sensor, value: 100)
      expect(reading).not_to be_exceeds_threshold
    end
  end
end
