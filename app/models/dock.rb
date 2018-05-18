# frozen_string_literal: true

class Dock < ApplicationRecord
  belongs_to :station

  enum dock_type: %i[landingpad dockingport hangar]

  validates :dock_type, :station_id, presence: true
end
