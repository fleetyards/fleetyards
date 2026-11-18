# frozen_string_literal: true

module HangarPlans
  # How far the live hangar and the store moved since the plan was based on
  # them: ships it relies on that are gone or changed, ships added since, and
  # what the decided routes cost then and now.
  class Drift
    SOURCE_KINDS = %w[acquisition upgrade_step melt mark].freeze

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

    # A ship the update takes as what a route bought shows there instead.
    def new_vehicles
      @new_vehicles ||= plan.added_vehicles.where.not(id: progress.arrivals.map { |arrival| arrival.vehicle.id })
        .includes(model: MODEL_PRELOAD).order(:created_at).to_a
    end

    # What the update moves the plan on to: routes whose ship arrived, and
    # upgrades still to buy that the user holds now.
    def progress
      @progress ||= Progress.new(plan)
    end

    private def find_missing_sources
      routes = acquisitions.select(&:source_missing?).reject { |acquisition| moving_on?(acquisition) }.map do |acquisition|
        SourceIssue.new(kind: "acquisition", record_id: acquisition.id, planned_model: acquisition.start_model, current_model: nil)
      end
      steps = plan.upgrade_steps.includes(:origin_model, :target_model, :hangar_pledge_item, :buyback_pledge).select(&:source_missing?).reject { |step| held_step_ids.include?(step.id) }.map do |step|
        SourceIssue.new(kind: "upgrade_step", record_id: step.id, planned_model: step.target_model, current_model: nil)
      end
      gone = melts.select(&:vehicle_missing?).map do |melt|
        SourceIssue.new(kind: "melt", record_id: melt.id, planned_model: melt.model, current_model: nil)
      end
      kept = plan.vehicle_marks.where(mark: "keep").where.not(vehicle_id: plan.pledged_vehicle_ids.to_a).includes(:model).map do |mark|
        SourceIssue.new(kind: "mark", record_id: mark.id, planned_model: mark.model, current_model: nil)
      end

      routes + steps + gone + kept
    end

    private def find_changed_sources
      routes = acquisitions.select(&:source_changed?).reject { |acquisition| moving_on?(acquisition) }.map do |acquisition|
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
      missing_sources.any? || changed_sources.any? || new_vehicles.any? || progress.any? ||
        previous_total != current_total
    end

    # Brings the plan up to the live hangar without discarding the user's
    # edits: what the user carried out moves the plan on, added ships wait for
    # the user to decide on them, routes and melts of ships lost otherwise stay
    # flagged, and prices are taken again as of now. A mark of a ship that left
    # the hangar goes, since the plan shows it nowhere to edit; one hidden for
    # now stays, to apply again once it is back.
    def rebase!
      HangarPlan.transaction do
        progress.apply!
        @progress = nil
        @new_vehicles = nil

        HangarPlanVehicleMark.write(plan, plan.added_vehicles.to_a, "pending")
        gone = plan.vehicle_marks.where.not(vehicle_id: plan.pledged_vehicles.select(:id))
          .where.not(vehicle_id: plan.user.vehicles.where(hidden: true).select(:id))
        plan.vehicle_marks.where(vehicle_id: nil).or(gone).delete_all

        plan.acquisitions.includes(:start_model, :buyback_pledge).find_each do |acquisition|
          acquisition.update_columns(price_snapshot: acquisition.list_price)
        end
        plan.upgrade_steps.includes(:origin_model, :target_model, :buyback_pledge).find_each do |step|
          step.update_columns(price_snapshot: step.list_price)
        end
        plan.melts.includes(:model).find_each { |melt| melt.update_columns(value_snapshot: melt.list_value) }

        plan.update!(based_on_at: Time.current, based_on_vehicle_ids: plan.live_vehicles.pluck(:id))
      end
    end

    private def moving_on?(acquisition)
      @moving_on_ids ||= progress.arrivals.map { |arrival| arrival.acquisition.id }.to_set
      @moving_on_ids.include?(acquisition.id)
    end

    private def held_step_ids
      @held_step_ids ||= progress.held_upgrades.map { |held| held.step.id }.to_set
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
