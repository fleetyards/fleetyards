# frozen_string_literal: true

module HangarPlans
  # What a plan costs, in USD. A decided slot costs what its chosen routes cost;
  # an undecided one is a range between its cheapest and dearest candidate; an
  # open slot and every unit without a route are gaps rather than assumed
  # store purchases. A price nobody knows is reported, never counted as zero.
  class Summary
    ISSUE_KINDS = %w[missing_price not_on_sale].freeze

    SlotCost = Data.define(:slot_id, :state, :min_cost, :max_cost, :unresolved_count, :complete)
    Issue = Data.define(:kind, :name, :slot_id)

    attr_reader :plan, :slot_costs, :issues, :melt_credit, :estimated_melts_count

    def initialize(plan)
      @plan = plan
      @issues = []
      @slot_costs = slots.map { |slot| cost_for(slot) }
      @melt_credit = melts.sum { |melt| melt_value(melt) }
      @estimated_melts_count = melts.count(&:estimated?)
    end

    def spend_min = slot_costs.sum(&:min_cost)

    def spend_max = slot_costs.sum(&:max_cost)

    def starting_credit = plan.starting_credit

    def credit_total = starting_credit + melt_credit

    def net_min = spend_min - melt_credit

    def net_max = spend_max - melt_credit

    def cash_needed_min = [spend_min - credit_total, 0].max

    def cash_needed_max = [spend_max - credit_total, 0].max

    def remaining_credit_min = [credit_total - spend_max, 0].max

    def remaining_credit_max = [credit_total - spend_min, 0].max

    def unresolved_count = slot_costs.sum(&:unresolved_count)

    def count_of(state) = slot_costs.count { |cost| cost.state == state }

    def complete?
      issues.empty? && unresolved_count.zero? && count_of("undecided").zero?
    end

    # The decided spend as priced when each route was planned, next to today's,
    # so a price change since then shows.
    def decided_spend(snapshot: false)
      slots.select { |slot| slot.state == "decided" }.sum do |slot|
        candidate = slot.candidates.first
        candidate.acquisitions.first(slot.quantity).sum do |acquisition|
          route_cost(acquisition, candidate, snapshot:, record: false) || 0
        end
      end
    end

    def melt_credit_at(snapshot: false)
      melts.sum { |melt| (snapshot ? melt.snapshot_value : melt.value) || 0 }
    end

    private def slots
      @slots ||= plan.slots.includes(candidates: [
        :model_paint,
        {model: :manufacturer},
        {acquisitions: [:start_model, :buyback_pledge, {upgrade_steps: %i[origin_model target_model buyback_pledge]}]}
      ]).to_a
    end

    private def melts
      @melts ||= plan.melts.includes(:model).to_a
    end

    private def cost_for(slot)
      case slot.state
      when "open"
        SlotCost.new(slot_id: slot.id, state: "open", min_cost: 0, max_cost: 0,
          unresolved_count: slot.quantity, complete: false)
      when "decided" then decided_cost(slot)
      else undecided_cost(slot)
      end
    end

    private def decided_cost(slot)
      candidate = slot.candidates.first
      acquisitions = candidate.acquisitions.first(slot.quantity)
      costs = acquisitions.map { |acquisition| route_cost(acquisition, candidate, slot_id: slot.id) }
      total = costs.compact.sum(0)
      unresolved = slot.quantity - acquisitions.size

      SlotCost.new(slot_id: slot.id, state: "decided", min_cost: total, max_cost: total,
        unresolved_count: unresolved, complete: unresolved.zero? && costs.none?(&:nil?))
    end

    private def undecided_cost(slot)
      costs = slot.candidates.map do |candidate|
        needed = [slot.quantity - owned_available.fetch(candidate.model_id, 0), 0].max
        next 0 if needed.zero?

        unit = sum_known([candidate.model.pledge_price, *candidate.extras.map(&:pledge_price)])
        if unit.nil?
          issue("missing_price", candidate.model.name, slot.id)
          next
        end

        needed * unit
      end

      known = costs.compact
      SlotCost.new(slot_id: slot.id, state: "undecided", min_cost: known.min || 0, max_cost: known.max || 0,
        unresolved_count: 0, complete: false)
    end

    # Nil when any part of the route has no price, after reporting which.
    private def route_cost(acquisition, candidate, slot_id: nil, snapshot: false, record: true)
      parts = [[snapshot ? acquisition.snapshot_price : acquisition.price, acquisition.start_model.name]]

      if acquisition.start_kind == "store" && !acquisition.start_model.on_sale && record
        issue("not_on_sale", acquisition.start_model.name, slot_id)
      end

      acquisition.upgrade_steps.each do |step|
        parts << [snapshot ? step.snapshot_price : step.price, "#{step.origin_model.name} → #{step.target_model.name}"]
        if step.source_kind == "store" && !step.target_model.on_sale && record
          issue("not_on_sale", "#{step.origin_model.name} → #{step.target_model.name}", slot_id)
        end
      end

      # A ship already in the hangar comes with whatever it was fitted with.
      unless acquisition.start_kind == "owned"
        candidate.extras.each { |extra| parts << [extra.pledge_price, extra.name] }
      end

      missing = parts.select { |price, _| price.nil? }
      missing.each { |_, name| issue("missing_price", name, slot_id) } if record
      return if missing.any?

      parts.sum { |price, _| price }
    end

    private def melt_value(melt)
      value = melt.value
      issue("missing_price", melt.model.name, nil) if value.nil?
      value || 0
    end

    private def owned_available
      @owned_available ||= plan.live_vehicles.where.not(id: plan.used_vehicle_ids).group(:model_id).count
    end

    private def sum_known(prices)
      prices.sum if prices.none?(&:nil?)
    end

    private def issue(kind, name, slot_id)
      entry = Issue.new(kind:, name:, slot_id:)
      @issues << entry unless @issues.include?(entry)
    end
  end
end
