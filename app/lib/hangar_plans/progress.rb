# frozen_string_literal: true

module HangarPlans
  # What the user carried out of the plan since it was based. The hangar sync
  # records an upgraded or bought-back ship as a new one and lets the old one
  # go, so a route whose start left the hangar goes on from the furthest ship
  # along it that arrived. A melt whose ship is gone, with no route left to buy
  # it back, is done: its credit is now the user's.
  class Progress
    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def apply!
      pool = arrived_vehicles
      # A bundled start rides on another; it moves on first, or the other's
      # move would take it along.
      routes = plan.acquisitions.where.not(hangar_plan_candidate_id: nil)
        .includes(:upgrade_steps, :buyback_pledge, :bundled_with, source_vehicle: :model)
        .sort_by { |acquisition| (acquisition.start_kind == "bundled") ? 0 : 1 }
      routes.each { |acquisition| advance(acquisition, pool) }

      finish_melts
    end

    private def advance(acquisition, pool)
      steps = acquisition.ordered_steps

      if acquisition.source_changed?
        vehicle = acquisition.live_source_vehicle
        index = steps.index { |step| step.to_model_id == vehicle.model_id }
        move_on(acquisition, vehicle, steps.first(index + 1)) if index
      elsif start_gone?(acquisition)
        reached = steps.each_with_index.map { |step, index| [step.to_model_id, index + 1] }
        reached.unshift([acquisition.start_model_id, 0]) unless acquisition.start_kind == "owned"

        reached.reverse_each do |model_id, done|
          vehicle = pool.find { |candidate| candidate.model_id == model_id }
          next if vehicle.nil?

          pool.delete(vehicle)
          return move_on(acquisition, vehicle, steps.first(done))
        end
      end
    end

    private def start_gone?(acquisition)
      return true if acquisition.source_missing?

      acquisition.start_kind == "melted" && acquisition.source_melt.vehicle_missing?
    end

    private def move_on(acquisition, vehicle, done_steps)
      done_steps.each(&:destroy!)
      acquisition.upgrade_steps.reset
      acquisition.assign_attributes(
        start_kind: "owned", source_vehicle: vehicle, start_model: vehicle.model,
        buyback_pledge: nil, bundled_with: nil, uses_buyback_token: false, price_override: nil
      )
      # The route was valid when planned and the ship is the user's now; what
      # else the old start spent may be gone, which drift goes on to show.
      acquisition.save!(validate: false)
    end

    # Ships the plan has not placed yet: bought since it was based, or still
    # waiting for the user to decide on them.
    private def arrived_vehicles
      scope = plan.live_vehicles.where.not(id: plan.used_vehicle_ids)
        .where.not(id: plan.vehicle_marks.where(mark: "keep").select(:vehicle_id))
      fresh = if plan.based_on_vehicle_ids.nil?
        scope.where(created_at: plan.based_on_at..)
      else
        scope.where.not(id: plan.based_on_vehicle_ids)
      end
      pending = scope.where(id: plan.vehicle_marks.where(mark: "pending").select(:vehicle_id))

      (fresh.order(created_at: :desc).to_a + pending.order(created_at: :desc).to_a).uniq
    end

    # A credit the user entered was what they held before melting; one read
    # from RSI is read again by the next sync.
    private def finish_melts
      credit = 0
      plan.melts.includes(:vehicle).to_a.select(&:vehicle_missing?).each do |melt|
        next if melt.bought_back_starts.exists?

        credit += melt.snapshot_value || 0
        melt.destroy!
      end

      plan.update!(starting_credit: plan.starting_credit + credit) if plan.starting_credit && credit.positive?
    end
  end
end
