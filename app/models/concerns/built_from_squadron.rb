# frozen_string_literal: true

# A team on an event or event template that stands for one of the fleet's
# squadrons or teams. It starts out named and described like it; only what was
# left blank is filled, so a squadron can field "Alpha -- Escort" without the
# name being overwritten.
module BuiltFromSquadron
  extend ActiveSupport::Concern

  included do
    belongs_to :fleet_squadron, optional: true

    validate :fleet_squadron_belongs_to_the_fleet

    before_validation :take_over_squadron_details, on: :create
  end

  private def take_over_squadron_details
    return if fleet_squadron.blank?

    self.title = fleet_squadron.name if title.blank?
    self.description = fleet_squadron.short_description.presence if description.blank?
  end

  private def fleet_squadron_belongs_to_the_fleet
    return if fleet_squadron_id.blank?

    # An id that names no squadron would otherwise only be stopped by the
    # foreign key, as a 500.
    return errors.add(:fleet_squadron, :not_in_fleet) if fleet_squadron.blank?

    fleet_id = squadron_fleet_id
    return if fleet_id.blank? || fleet_squadron.fleet_id == fleet_id

    errors.add(:fleet_squadron, :not_in_fleet)
  end
end
