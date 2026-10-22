# frozen_string_literal: true

module HangarPlans
  # Puts the ships a plan still has to obtain on the wishlist: every unit of a
  # decided slot that is not a ship the user already has. A ship they hold but
  # gave no route, or already wish for, counts as had, so running it again adds
  # nothing. The hangar itself is left alone; RSI sync owns the purchased ships.
  class WishlistApply
    Result = Data.define(:added, :skipped)

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def run
      added = 0
      skipped = 0

      had = plan.live_vehicles.where.not(id: plan.used_vehicle_ids).group(:model_id).count
      plan.user.vehicles.wanted.where(loaner: false).group(:model_id).count.each do |model_id, count|
        had[model_id] = had.fetch(model_id, 0) + count
      end

      Vehicle.transaction do
        plan.slots.includes(candidates: [:model, :acquisitions]).each do |slot|
          candidate = slot.decided_candidate
          next if candidate.nil?

          owned = candidate.acquisitions.count { |acquisition| acquisition.start_kind == "owned" }
          needed = [slot.quantity - owned, 0].max
          covered = [had.fetch(candidate.model_id, 0), needed].min
          had[candidate.model_id] = had.fetch(candidate.model_id, 0) - covered

          (needed - covered).times do
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
