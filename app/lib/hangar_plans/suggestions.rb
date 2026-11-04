# frozen_string_literal: true

module HangarPlans
  # What a plan could do better, judged on the hangar it ends with: the units of
  # its decided slots and the hangar ships it leaves alone. Ships it melts or
  # upgrades away are gone by then, so they never count, and neither does a ship
  # already meant to go: one marked to change, or picked as the start of a slot
  # still choosing its ship.
  class Suggestions
    REDUNDANCY_KINDS = %w[duplicate role].freeze
    LEAVING_STATUSES = %w[change unrouted].freeze

    # Ships of one model, or of one role: the same classification, size and
    # most specific focus.
    Redundancy = Data.define(:kind, :model, :classification, :size, :focus, :entries)

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def redundancies
      duplicates + roles
    end

    # What the plan decided so far for a hangar ship it holds.
    def status_of(vehicle)
      return if vehicle.nil?

      @statuses ||= comparison.vehicles.to_h { |entry| [entry.vehicle.id, entry.status] }
      @statuses[vehicle.id]
    end

    private def duplicates
      fleet.group_by { |entry| entry.model.id }.values.select { |entries| entries.size > 1 }.map do |entries|
        model = entries.first.model
        Redundancy.new(kind: "duplicate", model:, classification: model.classification, size: model.size,
          focus: model.foci.first, entries:)
      end
    end

    # Only a role more than one model fills: one model held twice is already a
    # duplicate.
    private def roles
      fleet.group_by { |entry| role(entry.model) }.filter_map do |key, entries|
        next if key.nil? || entries.map { |entry| entry.model.id }.uniq.size < 2

        classification, size, focus = key
        Redundancy.new(kind: "role", model: nil, classification:, size:, focus:,
          entries: entries.sort_by { |entry| [entry.model.pledge_price || 0, entry.model.name] })
      end
    end

    private def role(model)
      key = [model.classification, model.size, model.foci.first]
      key if key.all?(&:present?)
    end

    private def fleet
      @fleet ||= comparison.fleet.reject do |entry|
        entry.slot.nil? && LEAVING_STATUSES.include?(status_of(entry.vehicle))
      end
    end

    private def comparison
      @comparison ||= Comparison.new(plan)
    end
  end
end
