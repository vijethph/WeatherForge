# frozen_string_literal: true

class MarineWeather < ApplicationRecord
  belongs_to :location

  validates :recorded_at, :location_id, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :last_24_hours, -> { where("recorded_at > ?", 24.hours.ago) }
end
