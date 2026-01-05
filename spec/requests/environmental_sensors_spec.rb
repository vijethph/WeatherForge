# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EnvironmentalSensors API" do
  let(:location) { create(:location) }
  let!(:active_sensor) { create(:environmental_sensor, :active, location: location) }
  let!(:inactive_sensor) { create(:environmental_sensor, :inactive, location: location) }

  describe "GET /environmental_sensors" do
    context "with HTML format" do
      it "returns success" do
        get environmental_sensors_path
        expect(response).to have_http_status(:ok)
      end

      it "displays all sensors" do
        get environmental_sensors_path
        expect(response.body).to include(CGI.escapeHTML(active_sensor.name))
        expect(response.body).to include(CGI.escapeHTML(inactive_sensor.name))
      end
    end

    context "with JSON format" do
      it "returns all sensors" do
        get environmental_sensors_path(format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.length).to eq(2)
      end

      it "filters by status" do
        get environmental_sensors_path(format: :json, status: "active")

        json = response.parsed_body
        expect(json.length).to eq(1)
        expect(json.first["name"]).to eq(active_sensor.name)
      end

      it "filters by sensor type" do
        create(:environmental_sensor, sensor_type: "pm25", location: location)

        get environmental_sensors_path(format: :json, sensor_type: "pm25")

        json = response.parsed_body
        expect(json.length).to eq(1)
        expect(json.first["sensor_type"]).to eq("pm25")
      end

      it "filters by location" do
        other_location = create(:location, name: "Another City")
        create(:environmental_sensor, location: other_location)

        get environmental_sensors_path(format: :json, location_id: location.id)

        json = response.parsed_body
        expect(json.length).to eq(2)
        json.each do |sensor|
          expect(sensor["location_id"]).to eq(location.id)
        end
      end

      it "searches by query" do
        searchable_sensor = create(:environmental_sensor, name: "UniqueSearchName", location: location)

        get environmental_sensors_path(format: :json, query: "UniqueSearch")

        json = response.parsed_body
        expect(json.length).to eq(1)
        expect(json.first["name"]).to eq(searchable_sensor.name)
      end
    end
  end

  describe "GET /environmental_sensors/:id" do
    context "with HTML format" do
      it "returns success" do
        get environmental_sensor_path(active_sensor)
        expect(response).to have_http_status(:ok)
      end

      it "displays sensor details" do
        get environmental_sensor_path(active_sensor)
        expect(response.body).to include(CGI.escapeHTML(active_sensor.name))
        expect(response.body).to include(CGI.escapeHTML(active_sensor.manufacturer))
      end
    end

    context "with JSON format" do
      it "returns sensor data" do
        get environmental_sensor_path(active_sensor, format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["id"]).to eq(active_sensor.id)
        expect(json["name"]).to eq(active_sensor.name)
        expect(json["sensor_type"]).to eq(active_sensor.sensor_type)
      end

      it "includes location data" do
        get environmental_sensor_path(active_sensor, format: :json)

        json = response.parsed_body
        expect(json["location"]["name"]).to eq(location.name)
      end

      it "includes recent readings if available" do
        create(:environmental_reading, environmental_sensor: active_sensor)

        get environmental_sensor_path(active_sensor, format: :json)

        json = response.parsed_body
        expect(json["latest_reading"]).to be_present
      end

      it "returns 404 for non-existent sensor" do
        get environmental_sensor_path(id: 99999, format: :json)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /environmental_sensors" do
    let(:valid_attributes) do
      {
        name: "New Sensor",
        sensor_type: "pm25",
        manufacturer: "AirSense",
        model_number: "AS-100",
        installation_date: Date.today,
        latitude: 37.7749,
        longitude: -122.4194,
        status: "active",
        location_id: location.id
      }
    end

    context "with valid parameters" do
      it "creates a new sensor" do
        expect do
          post environmental_sensors_path, params: { environmental_sensor: valid_attributes }
        end.to change(EnvironmentalSensor, :count).by(1)
      end

      it "redirects to sensor show page" do
        post environmental_sensors_path, params: { environmental_sensor: valid_attributes }
        expect(response).to redirect_to(environmental_sensor_path(EnvironmentalSensor.last))
      end

      it "sets flash notice" do
        post environmental_sensors_path, params: { environmental_sensor: valid_attributes }
        expect(flash[:notice]).to eq("Sensor created successfully")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          name: "",
          sensor_type: "invalid_type",
          latitude: 200
        }
      end

      it "does not create a new sensor" do
        expect do
          post environmental_sensors_path, params: { environmental_sensor: invalid_attributes }
        end.not_to change(EnvironmentalSensor, :count)
      end

      it "returns unprocessable entity status" do
        post environmental_sensors_path(format: :json), params: { environmental_sensor: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with JSON format" do
      it "returns created sensor JSON" do
        post environmental_sensors_path(format: :json), params: { environmental_sensor: valid_attributes }

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["name"]).to eq("New Sensor")
      end

      it "returns errors for invalid data" do
        post environmental_sensors_path(format: :json), params: { environmental_sensor: { name: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "PATCH /environmental_sensors/:id" do
    let(:new_attributes) do
      {
        name: "Updated Sensor Name",
        status: "maintenance"
      }
    end

    context "with valid parameters" do
      it "updates the sensor" do
        patch environmental_sensor_path(active_sensor), params: { environmental_sensor: new_attributes }

        active_sensor.reload
        expect(active_sensor.name).to eq("Updated Sensor Name")
        expect(active_sensor.status).to eq("maintenance")
      end

      it "redirects to sensor show page" do
        patch environmental_sensor_path(active_sensor), params: { environmental_sensor: new_attributes }
        expect(response).to redirect_to(environmental_sensor_path(active_sensor))
      end
    end

    context "with invalid parameters" do
      it "does not update the sensor" do
        original_name = active_sensor.name
        patch environmental_sensor_path(active_sensor), params: { environmental_sensor: { sensor_type: "invalid" } }

        active_sensor.reload
        expect(active_sensor.name).to eq(original_name)
      end
    end
  end

  describe "DELETE /environmental_sensors/:id" do
    it "destroys the sensor" do
      expect do
        delete environmental_sensor_path(active_sensor)
      end.to change(EnvironmentalSensor, :count).by(-1)
    end

    it "redirects to sensors index" do
      delete environmental_sensor_path(active_sensor)
      expect(response).to redirect_to(environmental_sensors_path)
    end

    it "sets flash notice" do
      delete environmental_sensor_path(active_sensor)
      expect(flash[:notice]).to eq("Sensor removed successfully")
    end

    context "with JSON format" do
      it "returns no content status" do
        delete environmental_sensor_path(active_sensor, format: :json)
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "GET /environmental_sensors/nearby" do
    it "finds sensors within radius" do
      create(:environmental_sensor, latitude: 37.7750, longitude: -122.4195, location: location)
      create(:environmental_sensor, latitude: 40.7128, longitude: -74.0060, location: location)

      get nearby_environmental_sensors_path(format: :json), params: { latitude: 37.7749, longitude: -122.4194, radius: 1000 }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /environmental_sensors/map_data" do
    it "returns GeoJSON data for map display" do
      get map_data_environmental_sensors_path(format: :json)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["type"]).to eq("FeatureCollection")
      expect(json["features"]).to be_an(Array)
    end

    it "includes sensor properties in GeoJSON" do
      get map_data_environmental_sensors_path(format: :json)

      json = response.parsed_body
      feature = json["features"].first
      expect(feature["properties"]["name"]).to be_present
      expect(feature["properties"]["sensor_type"]).to be_present
      expect(feature["geometry"]["coordinates"]).to be_an(Array)
    end
  end
end
