# frozen_string_literal: true

class VehicleLogEntry < ApplicationRecord
  belongs_to :vehicle, touch: true

  scope :public_entries, -> { where(public: true) }
  scope :chronological, -> { order(logged_at: :desc, created_at: :desc) }

  before_validation -> { self.logged_at ||= Time.current }, on: :create

  validates :title, presence: true, length: {maximum: 255}
  validates :logged_at, presence: true
end
