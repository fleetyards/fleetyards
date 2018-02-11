# frozen_string_literal: true

class FleetMembership < ApplicationRecord
  belongs_to :user, required: false
  belongs_to :fleet
end
