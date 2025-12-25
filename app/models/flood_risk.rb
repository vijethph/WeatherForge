# frozen_string_literal: true

class FloodRisk < ApplicationRecord
  belongs_to :location

  validates :recorded_at, :location_id, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :recent_10_days, -> { where("recorded_at > ?", 10.days.ago) }

  SEVERITY_LEVELS = {
    "low" => { color: "green", icon: "✓" },
    "moderate" => { color: "yellow", icon: "⚠" },
    "high" => { color: "red", icon: "⛔" }
  }.freeze

  def severity_info
    SEVERITY_LEVELS[flood_severity] || {}
  end
end
