# frozen_string_literal: true

module HangarPlans
  # What the user carried out of the plan since it was based. The hangar sync
  # records an upgraded or bought-back ship as a new one and lets the old one
  # go, so a route whose start left the hangar goes on from the furthest ship
  # along it that arrived. A route that buys its start goes on from that ship
  # once it arrives, even while the buy-back list, synced on its own, still
  # names the pledge. An upgrade still to buy that the user now holds is taken
  # from the hangar. A melt whose ship is gone, with no route left to buy it
  # back, is done: its credit is now the user's.
  class Progress
    # Starts bought rather than taken from the hangar. A bundled ship comes
    # with a pledge bought back, so it arrives with it.
    PURCHASED_KINDS = %w[store ingame buyback].freeze
    # Upgrades the plan still has to pay for.
    PAID_STEP_KINDS = %w[store buyback].freeze

    Arrival = Data.define(:acquisition, :vehicle, :done_steps)
    HeldUpgrade = Data.define(:step, :item)

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def arrivals
      @arrivals ||= find_arrivals
    end

    def held_upgrades
      @held_upgrades ||= find_held_upgrades
    end

    def any?
      arrivals.any? || held_upgrades.any?
    end

    def apply!
      arrivals.each { |arrival| move_on(arrival) }
      held_upgrades.each { |held| take_from_hangar(held) }

      finish_melts
    end

    private def find_arrivals
      @bought_back_melt_ids = []
      pool = arrived_vehicles
      # A bundled start rides on another; it moves on first, or the other's
      # move would take it along.
      routes = plan.acquisitions.where.not(hangar_plan_candidate_id: nil)
        .includes(:upgrade_steps, :buyback_pledge, :bundled_with, source_vehicle: :model)
        .sort_by { |acquisition| (acquisition.start_kind == "bundled") ? 0 : 1 }
      routes.filter_map { |acquisition| arrival_for(acquisition, pool) }
    end

    private def arrival_for(acquisition, pool)
      steps = acquisition.ordered_steps

      if acquisition.source_changed?
        vehicle = acquisition.live_source_vehicle
        index = steps.index { |step| step.to_model_id == vehicle.model_id }
        return Arrival.new(acquisition:, vehicle:, done_steps: steps.first(index + 1)) if index
      end

      candidates = if start_gone?(acquisition)
        pool
      elsif awaiting_purchase?(acquisition)
        pool.select { |vehicle| @fresh_ids.include?(vehicle.id) || vehicle.created_at >= acquisition.created_at }
      end
      return if candidates.nil?

      reached = steps.each_with_index.map { |step, index| [step.to_model_id, index + 1] }
      reached.unshift([acquisition.start_model_id, 0]) unless acquisition.start_kind == "owned"

      reached.reverse_each do |model_id, done|
        vehicle = candidates.find { |candidate| candidate.model_id == model_id }
        next if vehicle.nil?

        pool.delete(vehicle)
        @bought_back_melt_ids << acquisition.source_melt&.id if acquisition.start_kind == "melted"
        return Arrival.new(acquisition:, vehicle:, done_steps: steps.first(done))
      end
      nil
    end

    private def start_gone?(acquisition)
      case acquisition.start_kind
      when "owned" then left_hangar?(acquisition.source_vehicle)
      when "melted" then acquisition.source_missing? || left_hangar?(acquisition.source_melt.vehicle)
      else acquisition.source_missing?
      end
    end

    private def awaiting_purchase?(acquisition)
      return true if PURCHASED_KINDS.include?(acquisition.start_kind)

      acquisition.start_kind == "bundled" && acquisition.bundled_with&.start_kind == "buyback"
    end

    # A ship hidden for now is still the user's, to count again once it is back.
    private def left_hangar?(vehicle)
      vehicle.nil? || (plan.pledged_vehicle_ids.exclude?(vehicle.id) && !vehicle.hidden)
    end

    private def move_on(arrival)
      acquisition = arrival.acquisition
      arrival.done_steps.each(&:destroy!)
      acquisition.upgrade_steps.reset
      acquisition.assign_attributes(
        start_kind: "owned", source_vehicle: arrival.vehicle, start_model: arrival.vehicle.model,
        buyback_pledge: nil, bundled_with: nil, uses_buyback_token: false, price_override: nil
      )
      # The route was valid when planned and the ship is the user's now; what
      # else the old start spent may be gone, which drift goes on to show.
      acquisition.save!(validate: false)
    end

    # Ships the plan has not placed yet: bought since it was based, or still
    # waiting for the user to decide on them.
    private def arrived_vehicles
      fresh = plan.added_vehicles.where.not(id: plan.vehicle_marks.where(mark: "keep").select(:vehicle_id))
        .includes(model: MODEL_PRELOAD).order(created_at: :desc).to_a
      pending = plan.live_vehicles.where.not(id: plan.used_vehicle_ids)
        .where(id: plan.vehicle_marks.where(mark: "pending").select(:vehicle_id))
      @fresh_ids = fresh.map(&:id).to_set

      (fresh + pending.includes(model: MODEL_PRELOAD).order(created_at: :desc).to_a).uniq
    end

    # Each upgrade the user holds pays for as many steps as they hold of it,
    # in the order the routes were planned. Steps an arrival completes are
    # spent already.
    private def find_held_upgrades
      done = arrivals.flat_map { |arrival| arrival.done_steps.map(&:id) }.to_set
      steps = plan.upgrade_steps.where(source_kind: PAID_STEP_KINDS).where.not(id: done.to_a)
        .includes(origin_model: MODEL_PRELOAD, target_model: MODEL_PRELOAD).order(:created_at, :position).to_a
      return [] if steps.empty?

      spare = Resources.new(plan).upgrades.select { |upgrade| upgrade.from_model && upgrade.to_model }.map do |upgrade|
        {upgrade:, left: upgrade.item.quantity - upgrade.used_count}
      end

      steps.filter_map do |step|
        held = spare.find do |entry|
          entry[:left].positive? && entry[:upgrade].from_model.id == step.from_model_id &&
            entry[:upgrade].to_model.id == step.to_model_id
        end
        next if held.nil?

        held[:left] -= 1
        HeldUpgrade.new(step:, item: held[:upgrade].item)
      end
    end

    private def take_from_hangar(held)
      held.step.update!(
        source_kind: "owned_ccu", hangar_pledge_item: held.item, buyback_pledge: nil,
        uses_buyback_token: false, price_override: nil
      )
    end

    # A credit the user entered was what they held before melting; one read
    # from RSI is read again by the next sync. A melt whose pledge a route
    # bought back spent its credit on that.
    private def finish_melts
      credit = 0
      plan.melts.includes(:vehicle).to_a.select { |melt| left_hangar?(melt.vehicle) }.each do |melt|
        next if melt.bought_back_starts.exists?

        credit += melt.snapshot_value || 0 unless @bought_back_melt_ids.include?(melt.id)
        melt.destroy!
      end

      plan.update!(starting_credit: plan.starting_credit + credit) if plan.starting_credit && credit.positive?
    end
  end
end
