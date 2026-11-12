# frozen_string_literal: true

# A service a ship can give a ship landed on it, with the icon the game shows
# for it. The same four on every ship, so they are kept once rather than per
# model.
class LandingService < ApplicationRecord
  has_one_attached :icon

  validates :key, presence: true, uniqueness: true, inclusion: {in: ModelBuild::LANDING_SERVICES}

  def self.ordered
    all.sort_by { |service| ModelBuild::LANDING_SERVICES.index(service.key) }
  end
end
