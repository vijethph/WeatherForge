# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EnvironmentalAlerts API" do
  let(:location) { create(:location) }
  let(:sensor) { create(:environmental_sensor, location: location) }
  let(:reading) { create(:environmental_reading, environmental_sensor: sensor) }
  let!(:active_alert) { create(:environmental_alert, :active, :high, :threshold_exceeded, environmental_sensor: sensor) }
  let!(:resolved_alert) { create(:environmental_alert, :resolved, :medium, :sensor_failure, environmental_sensor: sensor) }

  describe "GET /environmental_alerts" do
    context "with HTML format" do
      it "returns success" do
        get environmental_alerts_path
        expect(response).to have_http_status(:ok)
      end

      it "displays all alerts" do
        get environmental_alerts_path
        expect(response.body).to include("Environmental Alerts")
      end
    end

    context "with JSON format" do
      it "returns all alerts" do
        get environmental_alerts_path(format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.length).to eq(2)
      end

      it "filters by status" do
        get environmental_alerts_path(format: :json, status: "active")

        json = response.parsed_body
        expect(json.length).to eq(1)
        expect(json.first["id"]).to eq(active_alert.id)
      end

      it "filters by severity" do
        critical_alert = create(:environmental_alert, :critical, environmental_sensor: sensor)

        get environmental_alerts_path(format: :json, severity: "critical")

        json = response.parsed_body
        expect(json.length).to eq(1)
        expect(json.first["id"]).to eq(critical_alert.id)
      end

      it "filters by alert type" do
        threshold_alert = create(:environmental_alert, :threshold_exceeded, environmental_sensor: sensor)
        anomaly_alert = create(:environmental_alert, :anomaly, environmental_sensor: sensor)

        get environmental_alerts_path(format: :json, alert_type: "anomaly")

        json = response.parsed_body
        expect(json.length).to eq(1)
        expect(json.first["id"]).to eq(anomaly_alert.id)
      end

      it "filters by sensor" do
        other_sensor = create(:environmental_sensor, location: location)
        create(:environmental_alert, environmental_sensor: other_sensor)

        get environmental_alerts_path(format: :json, sensor_id: sensor.id)

        json = response.parsed_body
        expect(json.length).to eq(2)
        json.each do |alert|
          expect(alert["environmental_sensor_id"]).to eq(sensor.id)
        end
      end

      it "filters by location" do
        other_location = create(:location)
        other_sensor = create(:environmental_sensor, location: other_location)
        create(:environmental_alert, environmental_sensor: other_sensor)

        get environmental_alerts_path(format: :json, location_id: location.id)

        json = response.parsed_body
        alerts_location_ids = json.map { |a| a.dig("environmental_sensor", "location_id") }.uniq
        expect(alerts_location_ids).to eq([ location.id ])
      end

      it "limits results" do
        create_list(:environmental_alert, 60, environmental_sensor: sensor)

        get environmental_alerts_path(format: :json)

        json = response.parsed_body
        expect(json.length).to be <= 50
      end
    end
  end

  describe "GET /environmental_alerts/:id" do
    context "with HTML format" do
      it "returns success" do
        get environmental_alert_path(active_alert)
        expect(response).to have_http_status(:ok)
      end

      it "displays alert details" do
        get environmental_alert_path(active_alert)
        expect(response.body).to include(active_alert.message)
      end
    end

    context "with JSON format" do
      it "returns alert data" do
        get environmental_alert_path(active_alert, format: :json)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["id"]).to eq(active_alert.id)
        expect(json["message"]).to eq(active_alert.message)
      end

      it "includes sensor data" do
        get environmental_alert_path(active_alert, format: :json)

        json = response.parsed_body
        expect(json["environmental_sensor"]["name"]).to eq(sensor.name)
      end

      it "includes reading data if present" do
        alert_with_reading = create(:environmental_alert,
                                   environmental_sensor: sensor,
                                   environmental_reading: reading)

        get environmental_alert_path(alert_with_reading, format: :json)

        json = response.parsed_body
        expect(json["environmental_reading"]).to be_present
      end

      it "returns 404 for non-existent alert" do
        get environmental_alert_path(id: 99999, format: :json)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /environmental_alerts" do
    let(:valid_attributes) do
      {
        environmental_sensor_id: sensor.id,
        alert_type: "threshold_exceeded",
        severity: "high",
        message: "Test alert message"
      }
    end

    context "with valid parameters" do
      it "creates a new alert" do
        expect do
          post environmental_alerts_path, params: { environmental_alert: valid_attributes }
        end.to change(EnvironmentalAlert, :count).by(1)
      end

      it "redirects to alert show page" do
        post environmental_alerts_path, params: { environmental_alert: valid_attributes }
        expect(response).to redirect_to(environmental_alert_path(EnvironmentalAlert.last))
      end

      it "broadcasts to subscribers for critical alerts" do
        critical_attributes = valid_attributes.merge(severity: "critical")

        expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).at_least(:once)

        post environmental_alerts_path, params: { environmental_alert: critical_attributes }
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          alert_type: "invalid_type",
          severity: ""
        }
      end

      it "does not create an alert" do
        expect do
          post environmental_alerts_path, params: { environmental_alert: invalid_attributes }
        end.not_to change(EnvironmentalAlert, :count)
      end

      it "returns unprocessable entity status" do
        post environmental_alerts_path, params: { environmental_alert: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /environmental_alerts/:id/resolve" do
    it "resolves the alert" do
      patch resolve_environmental_alert_path(active_alert)

      active_alert.reload
      expect(active_alert.resolved_at).to be_present
    end

    it "accepts resolution note" do
      resolution_note = "Fixed by maintenance team"

      patch resolve_environmental_alert_path(active_alert),
            params: { resolution_note: resolution_note }

      active_alert.reload
      expect(active_alert.metadata["resolution_note"]).to eq(resolution_note)
    end

    it "redirects to alert show page" do
      patch resolve_environmental_alert_path(active_alert)
      expect(response).to redirect_to(environmental_alert_path(active_alert))
    end

    it "broadcasts resolution update" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:once)

      patch resolve_environmental_alert_path(active_alert)
    end

    context "with JSON format" do
      it "returns updated alert JSON" do
        patch resolve_environmental_alert_path(active_alert, format: :json),
              params: { resolution_note: "Test resolution" }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["resolved_at"]).to be_present
      end
    end

    it "returns 404 for non-existent alert" do
      patch resolve_environmental_alert_path(id: 99999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /environmental_alerts/:id" do
    it "destroys the alert" do
      expect do
        delete environmental_alert_path(active_alert)
      end.to change(EnvironmentalAlert, :count).by(-1)
    end

    it "redirects to alerts index" do
      delete environmental_alert_path(active_alert)
      expect(response).to redirect_to(environmental_alerts_path)
    end

    context "with JSON format" do
      it "returns no content status" do
        delete environmental_alert_path(active_alert, format: :json)
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "GET /environmental_alerts/summary" do
    it "returns alert summary statistics" do
      create(:environmental_alert, :critical, environmental_sensor: sensor)
      create(:environmental_alert, :high, environmental_sensor: sensor)
      create(:environmental_alert, :medium, environmental_sensor: sensor)

      get summary_environmental_alerts_path(format: :json)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key("total")
      expect(json).to have_key("active")
      expect(json).to have_key("resolved")
      expect(json).to have_key("by_severity")
    end
  end

  describe "GET /environmental_alerts/timeline" do
    it "returns alerts in timeline format" do
      get timeline_environmental_alerts_path(format: :json)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to be_an(Array)
    end

    it "groups alerts by time period" do
      get timeline_environmental_alerts_path(format: :json, group_by: "hour")

      json = response.parsed_body
      expect(json.first).to have_key("time")
      expect(json.first).to have_key("count")
    end
  end
end
