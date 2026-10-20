# frozen_string_literal: true

module HangarPlans
  # How far the live hangar and the store moved since the plan was based on
  # them: ships it relies on that are gone or changed, ships added since, and
  # what the decided routes cost then and now.
  class Drift
    SOURCE_KINDS = %w[acquisition upgrade_step melt].freeze

    SourceIssue = Data.define(:kind, :record_id, :planned_model, :current_model)

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def missing_sources
      @missing_sources ||= find_missing_sources
    end

    def changed_sources
      @changed_sources ||= find_changed_sources
    end

    def new_vehicles
      @new_vehicles ||= plan.live_vehicles.where(created_at: plan.based_on_at..).where.not(id: plan.used_vehicle_ids)
        .includes(model: MODEL_PRELOAD).order(:created_at).to_a
    end

    private def find_missing_sources
      routes = acquisitions.select(&:source_missing?).map do |acquisition|
        SourceIssue.new(kind: "acquisition", record_id: acquisition.id, planned_model: acquisition.start_model, current_model: nil)
      end
      steps = plan.upgrade_steps.includes(:origin_model, :target_model, :hangar_pledge_item, :buyback_pledge).select(&:source_missing?).map do |step|
        SourceIssue.new(kind: "upgrade_step", record_id: step.id, planned_model: step.target_model, current_model: nil)
      end
      gone = melts.select(&:vehicle_missing?).map do |melt|
        SourceIssue.new(kind: "melt", record_id: melt.id, planned_model: melt.model, current_model: nil)
      end

      routes + steps + gone
    end

    private def find_changed_sources
      routes = acquisitions.select(&:source_changed?).map do |acquisition|
        SourceIssue.new(kind: "acquisition", record_id: acquisition.id, planned_model: acquisition.start_model,
          current_model: acquisition.source_vehicle.model)
      end
      changed = melts.select(&:vehicle_changed?).map do |melt|
        SourceIssue.new(kind: "melt", record_id: melt.id, planned_model: melt.model, current_model: melt.vehicle.model)
      end

      routes + changed
    end

    def previous_total
      summary.decided_spend(snapshot: true) - summary.melt_credit_at(snapshot: true)
    end

    def current_total
      summary.decided_spend - summary.melt_credit_at
    end

    def drifted?
      missing_sources.any? || changed_sources.any? || new_vehicles.any? || previous_total != current_total
    end

    # Brings the plan up to the live hangar without discarding the user's
    # edits: added ships become decided slots kept as they are, lost ones stay
    # flagged, and prices are taken again as of now.
    def rebase!
      HangarPlan.transaction do
        new_ships = new_vehicles
        Builder.new(plan).copy_vehicles(Vehicle.where(id: new_ships.map(&:id)), keep: true) if new_ships.any?

        plan.acquisitions.includes(:start_model, :buyback_pledge).find_each do |acquisition|
          acquisition.update_columns(price_snapshot: acquisition.list_price)
        end
        plan.upgrade_steps.includes(:origin_model, :target_model, :buyback_pledge).find_each do |step|
          step.update_columns(price_snapshot: step.list_price)
        end
        plan.melts.includes(:model).find_each { |melt| melt.update_columns(value_snapshot: melt.list_value) }

        plan.update!(based_on_at: Time.current)
      end
    end

    private def summary
      @summary ||= Summary.new(plan)
    end

    private def acquisitions
      @acquisitions ||= plan.acquisitions.includes(:start_model, :buyback_pledge, source_vehicle: :model).to_a
    end

    private def melts
      @melts ||= plan.melts.includes(:model, vehicle: :model).to_a
    end
  end
end
