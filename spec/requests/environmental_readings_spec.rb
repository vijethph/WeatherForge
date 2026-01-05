# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EnvironmentalReadings API" do
  let(:location) { create(:location) }
  let(:sensor) { create(:environmental_sensor, location: location, sensor_type: :pm25) }
  let!(:older_reading) { create(:environmental_reading, environmental_sensor: sensor, recorded_at: 2.hours.ago) }
  let!(:recent_reading) { create(:environmental_reading, environmental_sensor: sensor, recorded_at: 1.hour.ago) }

  describe "GET /environmental_sensors/:sensor_id/readings" do
    context "with HTML format" do
      it "returns success" do
        get environmental_sensor_environmental_readings_path(sensor)
        expect(response).to have_http_status(:ok)
      end

      it "displays readings for sensor" do
        get environmental_sensor_environmental_readings_path(sensor)
        expect(response.body).to include("Readings")
      end
    end

    context "with JSON format" do
      it "returns all readings for sensor" do
        get environmental_sensor_environmental_readings_path(sensor, format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.length).to eq(2)
      end

      it "orders readings by recorded_at descending" do
        get environmental_sensor_environmental_readings_path(sensor, format: :json)

        json = response.parsed_body
        expect(json.first["id"]).to eq(recent_reading.id)
        expect(json.last["id"]).to eq(older_reading.id)
      end
    end
  end

  describe "POST /environmental_sensors/:sensor_id/readings" do
    let(:valid_attributes) do
      {
        parameter_name: "pm25",
        value: 35.5,
        unit: "µg/m³",
        recorded_at: Time.current
      }
    end

    context "with valid parameters" do
      it "creates a new reading" do
        expect do
          post environmental_sensor_environmental_readings_path(sensor), params: { environmental_reading: valid_attributes }
        end.to change(sensor.environmental_readings, :count).by(1)
      end

      it "creates alert if threshold exceeded" do
        exceeding_attributes = valid_attributes.merge(value: 100.0)

        expect do
          post environmental_sensor_environmental_readings_path(sensor), params: { environmental_reading: exceeding_attributes }
        end.to change(EnvironmentalAlert, :count)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { value: nil } }

      it "does not create a reading" do
        expect do
          post environmental_sensor_environmental_readings_path(sensor), params: { environmental_reading: invalid_attributes }
        end.not_to change(EnvironmentalReading, :count)
      end
    end
  end

  describe "DELETE /environmental_sensors/:sensor_id/readings/:id" do
    it "destroys the reading" do
      expect do
        delete environmental_sensor_environmental_reading_path(sensor, older_reading)
      end.to change(sensor.environmental_readings, :count).by(-1)
    end
  end
end
