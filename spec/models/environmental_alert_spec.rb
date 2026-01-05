# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnvironmentalAlert do
  describe "associations" do
    it "belongs to environmental_sensor" do
      alert = create(:environmental_alert)
      expect(alert.environmental_sensor).to be_present
    end

    it "optionally belongs to environmental_reading" do
      alert = create(:environmental_alert)
      alert.environmental_reading = nil
      expect(alert).to be_valid
    end
  end

  describe "validations" do
    it "validates presence of alert_type" do
      alert = build(:environmental_alert, alert_type: nil)
      expect(alert).not_to be_valid
      expect(alert.errors[:alert_type]).to include("can't be blank")
    end

    it "validates presence of severity" do
      alert = build(:environmental_alert, severity: nil)
      expect(alert).not_to be_valid
      expect(alert.errors[:severity]).to include("can't be blank")
    end

    it "validates presence of message" do
      alert = build(:environmental_alert, message: nil)
      expect(alert).not_to be_valid
      expect(alert.errors[:message]).to include("can't be blank")
    end

    it "validates alert_type is in allowed values" do
      alert = build(:environmental_alert, alert_type: "invalid_type")
      expect(alert).not_to be_valid
      expect(alert.errors[:alert_type]).to be_present
    end

    it "validates severity is in allowed values" do
      alert = build(:environmental_alert, severity: "invalid_severity")
      expect(alert).not_to be_valid
      expect(alert.errors[:severity]).to be_present
    end
  end

  describe "scopes" do
    let!(:active_alert) { create(:environmental_alert, :active) }
    let!(:resolved_alert) { create(:environmental_alert, :resolved) }
    let!(:critical_alert) { create(:environmental_alert, :critical) }
    let!(:high_alert) { create(:environmental_alert, :high) }

    describe ".active" do
      it "returns alerts that are not resolved" do
        expect(described_class.active).to include(active_alert, critical_alert, high_alert)
        expect(described_class.active).not_to include(resolved_alert)
      end
    end

    describe ".resolved" do
      it "returns alerts that have been resolved" do
        expect(described_class.resolved).to include(resolved_alert)
        expect(described_class.resolved).not_to include(active_alert)
      end
    end

    describe ".by_severity" do
      it "filters alerts by severity level" do
        expect(described_class.by_severity("critical")).to include(critical_alert)
        expect(described_class.by_severity("critical")).not_to include(high_alert)
      end
    end

    describe ".critical" do
      it "returns only critical alerts" do
        expect(described_class.critical).to include(critical_alert)
        expect(described_class.critical).not_to include(high_alert)
      end
    end

    describe ".high" do
      it "returns only high severity alerts" do
        expect(described_class.high).to include(high_alert)
        expect(described_class.high).not_to include(critical_alert)
      end
    end

    describe ".recent" do
      it "orders alerts by created_at descending" do
        older_alert = create(:environmental_alert)
        sleep(0.01)  # Ensure different timestamps
        newer_alert = create(:environmental_alert)

        expect(described_class.recent.first.id).to eq(newer_alert.id)
        expect(described_class.recent.second.id).to eq(older_alert.id)
      end

      it "limits results to 50" do
        create_list(:environmental_alert, 60)
        expect(described_class.recent.count).to eq(50)
      end
    end

    describe ".by_type" do
      it "filters alerts by type" do
        threshold_alert = create(:environmental_alert, :threshold_exceeded)
        anomaly_alert = create(:environmental_alert, :anomaly)

        expect(described_class.by_type("threshold_exceeded")).to include(threshold_alert)
        expect(described_class.by_type("threshold_exceeded")).not_to include(anomaly_alert)
      end
    end
  end

  describe "instance methods" do
    let(:alert) { create(:environmental_alert) }

    describe "#resolve!" do
      it "sets resolved_at to current time" do
        freeze_time do
          alert.resolve!
          expect(alert.resolved_at).to eq(Time.current)
        end
      end

      it "saves resolution note in metadata" do
        alert.resolve!(resolution_note: "Fixed by maintenance")
        expect(alert.metadata["resolution_note"]).to eq("Fixed by maintenance")
      end

      it "returns true on successful resolution" do
        expect(alert.resolve!).to be_truthy
      end
    end

    describe "#resolved?" do
      it "returns true when resolved_at is present" do
        alert.resolved_at = Time.current
        expect(alert).to be_resolved
      end

      it "returns false when resolved_at is nil" do
        alert.resolved_at = nil
        expect(alert).not_to be_resolved
      end
    end

    describe "#active?" do
      it "returns true when resolved_at is nil" do
        alert.resolved_at = nil
        expect(alert).to be_active
      end

      it "returns false when resolved_at is present" do
        alert.resolved_at = Time.current
        expect(alert).not_to be_active
      end
    end

    describe "#severity_color" do
      it "returns danger for critical severity" do
        alert.severity = "critical"
        expect(alert.severity_color).to eq("danger")
      end

      it "returns warning for high severity" do
        alert.severity = "high"
        expect(alert.severity_color).to eq("warning")
      end

      it "returns info for medium severity" do
        alert.severity = "medium"
        expect(alert.severity_color).to eq("info")
      end

      it "returns secondary for low severity" do
        alert.severity = "low"
        expect(alert.severity_color).to eq("secondary")
      end
    end

    describe "#alert_type_icon" do
      it "returns correct icon for each alert type" do
        expect(create(:environmental_alert, alert_type: "threshold_exceeded").alert_type_icon).to eq("⚠️")
        expect(create(:environmental_alert, alert_type: "anomaly").alert_type_icon).to eq("📊")
        expect(create(:environmental_alert, alert_type: "sensor_failure").alert_type_icon).to eq("🔧")
        expect(create(:environmental_alert, alert_type: "zone_alert").alert_type_icon).to eq("📍")
        expect(create(:environmental_alert, alert_type: "network_issue").alert_type_icon).to eq("🌐")
      end
    end

    describe "#duration" do
      it "returns duration in human-readable format when resolved" do
        alert.created_at = 2.hours.ago
        alert.resolved_at = 1.hour.ago

        expect(alert.duration).to match(/hour/)
      end

      it "returns nil when not resolved" do
        alert.resolved_at = nil
        expect(alert.duration).to be_nil
      end
    end

    describe "#time_active" do
      it "returns duration for resolved alerts" do
        alert.created_at = 2.hours.ago
        alert.resolved_at = 1.hour.ago

        expect(alert.time_active).to match(/hour/)
      end

      it "returns time since creation for active alerts" do
        alert.created_at = 30.minutes.ago
        alert.resolved_at = nil

        expect(alert.time_active).to be_present
      end
    end

    describe "#alert_type_humanized" do
      it "returns humanized alert type" do
        alert.alert_type = "threshold_exceeded"
        expect(alert.alert_type_humanized).to eq("Threshold Exceeded")
      end
    end
  end

  describe "callbacks" do
    describe "broadcast_alert_to_subscribers" do
      let(:sensor) { create(:environmental_sensor) }

      it "broadcasts critical alerts after creation" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).at_least(:once)

        create(:environmental_alert, :critical, environmental_sensor: sensor)
      end

      it "broadcasts high severity alerts after creation" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).at_least(:once)

        create(:environmental_alert, :high, environmental_sensor: sensor)
      end
    end

    describe "broadcast_resolution" do
      let(:alert) { create(:environmental_alert, :active, :critical) }

      it "broadcasts when alert is resolved" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:once)

        alert.resolve!
      end
    end
  end
end
