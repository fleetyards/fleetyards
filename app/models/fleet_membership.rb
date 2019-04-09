# frozen_string_literal: true

class FleetMembership < ApplicationRecord
  belongs_to :fleet
  belongs_to :user

  enum role: %i[member moderator admin]

  validates :role, presence: true
end
