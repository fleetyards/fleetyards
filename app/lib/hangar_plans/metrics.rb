# frozen_string_literal: true

module HangarPlans
  # Hangar figures for a list of ships, one entry per ship. The live hangar and
  # a plan both go through here, so the same hangar yields the same numbers.
  class Metrics
    Count = Data.define(:name, :count)

    def self.for(models)
      new(models).to_h
    end

    def self.plan_models(plan)
      plan.slots.includes(candidates: {model: MODEL_PRELOAD}).flat_map do |slot|
        candidate = slot.decided_candidate
        candidate ? Array.new(slot.quantity, candidate.model) : []
      end
    end

    def self.live_models(plan)
      plan.live_vehicles.includes(model: :manufacturer).map(&:model)
    end

    attr_reader :models

    def initialize(models)
      @models = models
    end

    def to_h
      lengths = models.filter_map { |model| model.length if model.length&.positive? }

      {
        total: models.size,
        unique_models_count: models.map(&:id).uniq.size,
        manufacturer_count: models.filter_map(&:manufacturer_id).uniq.size,
        total_crew: models.sum { |model| model.crew.to_i },
        total_cargo: models.sum { |model| model.cargo.to_f },
        total_pledge_value: models.sum { |model| model.pledge_price || 0 },
        flight_ready_count: models.count { |model| model.production_status == "flight-ready" },
        largest_ship: lengths.max,
        smallest_ship: lengths.min,
        classifications: counts(&:classification),
        sizes: counts(&:size),
        production_statuses: counts(&:production_status),
        manufacturers: counts { |model| model.manufacturer&.name }
      }
    end

    private def counts(&)
      models.filter_map(&).tally.sort_by { |name, count| [-count, name] }
        .map { |name, count| Count.new(name:, count:) }
    end
  end
end
