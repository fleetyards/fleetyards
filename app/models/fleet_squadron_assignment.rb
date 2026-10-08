# frozen_string_literal: true

class FleetSquadronAssignment < ApplicationRecord
  belongs_to :fleet_squadron
  belongs_to :assignable, polymorphic: true

  validates :fleet_squadron_id, uniqueness: {scope: %i[assignable_type assignable_id]}

  def self.ransackable_attributes(_auth_object = nil)
    %w[fleet_squadron_id assignable_type assignable_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_squadron assignable]
  end
end
