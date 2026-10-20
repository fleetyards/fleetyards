# frozen_string_literal: true

module HangarPlans
  # Puts the ships a plan still has to obtain on the wishlist: every unit of a
  # decided slot that is not a ship the user already has. The hangar itself is
  # left alone; RSI sync owns the purchased ships.
  class WishlistApply
    Result = Data.define(:added, :skipped)

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def run
      added = 0
      skipped = 0

      Vehicle.transaction do
        plan.slots.includes(candidates: [:model, :acquisitions]).each do |slot|
          candidate = slot.decided_candidate
          next if candidate.nil?

          owned = candidate.acquisitions.count { |acquisition| acquisition.start_kind == "owned" }
          [slot.quantity - owned, 0].max.times do
            vehicle = plan.user.vehicles.new(model: candidate.model, wanted: true)
            if vehicle.save
              added += 1
            else
              skipped += 1
            end
          end
        end
      end

      Result.new(added:, skipped:)
    end
  end
end
