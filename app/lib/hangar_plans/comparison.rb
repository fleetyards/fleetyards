# frozen_string_literal: true

module HangarPlans
  # A plan next to the live hangar: what happens to each ship the user has, and
  # how the count of each model changes. Only decided slots are targets; an
  # undecided slot has not said which ship it wants yet.
  class Comparison
    VEHICLE_STATUSES = %w[kept upgraded melted unassigned].freeze
    CHANGES = %w[added removed more fewer unchanged].freeze

    VehicleStatus = Data.define(:vehicle, :status, :target_model)
    ModelDiff = Data.define(:model, :left_count, :right_count, :change)
    Gap = Data.define(:slot, :model, :count)

    def self.diff(left_models, right_models)
      left = left_models.group_by(&:id)
      right = right_models.group_by(&:id)

      (left.keys | right.keys).map do |id|
        model = (left[id] || right[id]).first
        left_count = left.fetch(id, []).size
        right_count = right.fetch(id, []).size
        change =
          if left_count.zero? then "added"
          elsif right_count.zero? then "removed"
          elsif right_count > left_count then "more"
          elsif right_count < left_count then "fewer"
          else "unchanged"
          end

        ModelDiff.new(model:, left_count:, right_count:, change:)
      end.sort_by { |diff| [diff.model.name.downcase, diff.model.id] }
    end

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def vehicles
      melted = plan.melts.pluck(:vehicle_id).to_set
      routes = plan.acquisitions.where(start_kind: "owned", hangar_plan_candidate_id: decided_candidate_ids)
        .includes(upgrade_steps: {target_model: MODEL_PRELOAD})
        .index_by(&:source_vehicle_id)

      live_vehicles.map do |vehicle|
        route = routes[vehicle.id]
        if melted.include?(vehicle.id)
          VehicleStatus.new(vehicle:, status: "melted", target_model: nil)
        elsif route.nil?
          VehicleStatus.new(vehicle:, status: "unassigned", target_model: nil)
        elsif route.upgrade_steps.any?
          VehicleStatus.new(vehicle:, status: "upgraded", target_model: route.upgrade_steps.last.target_model)
        else
          VehicleStatus.new(vehicle:, status: "kept", target_model: vehicle.model)
        end
      end
    end

    def models
      self.class.diff(live_vehicles.map(&:model), after_models)
    end

    def gaps
      plan.slots.includes(candidates: [{model: MODEL_PRELOAD}, :acquisitions]).filter_map do |slot|
        candidate = slot.decided_candidate
        next if candidate.nil?

        missing = slot.quantity - candidate.acquisitions.size
        Gap.new(slot:, model: candidate.model, count: missing) if missing.positive?
      end
    end

    def metrics
      {live: Metrics.for(live_vehicles.map(&:model)), plan: Metrics.for(after_models)}
    end

    # The hangar once the plan is carried out: the ships its decided slots hold,
    # and every ship the plan neither uses nor melts, which stays. A ship left
    # out fills a unit of its own model that has no route yet, rather than being
    # counted twice.
    private def after_models
      @after_models ||= begin
        open_units = gaps.each_with_object(Hash.new(0)) { |gap, units| units[gap.model.id] += gap.count }
        left_out = vehicles.select { |entry| entry.status == "unassigned" }.map { |entry| entry.vehicle.model }

        staying = left_out.reject do |model|
          next false unless open_units[model.id].positive?

          open_units[model.id] -= 1
          true
        end

        Metrics.plan_models(plan) + staying
      end
    end

    # Routes on a slot that has not picked its ship yet say nothing about what
    # happens to the hangar.
    private def decided_candidate_ids
      plan.slots.includes(:candidates).filter_map { |slot| slot.decided_candidate&.id }
    end

    private def live_vehicles
      @live_vehicles ||= plan.live_vehicles.includes(model: MODEL_PRELOAD).order(:created_at).to_a
    end
  end
end
