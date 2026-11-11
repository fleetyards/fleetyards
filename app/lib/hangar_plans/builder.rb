# frozen_string_literal: true

module HangarPlans
  # Creates a plan, empty or filled from the hangar, the wishlist or another
  # plan. Every ship takes a slot of its own, and ships that share a model and
  # fitting sit next to each other.
  class Builder
    SOURCES = %w[empty hangar wishlist plan].freeze

    attr_reader :plan, :source, :source_plan

    def initialize(plan, source: "empty", source_plan: nil)
      @plan = plan
      @source = source.presence || "empty"
      @source_plan = source_plan
    end

    def run
      HangarPlan.transaction do
        plan.save!
        case source
        # Every hangar ship waits for the user to say whether it stays, is
        # upgraded or melts.
        when "hangar" then HangarPlanVehicleMark.write(plan, plan.live_vehicles.select(:id, :model_id), "pending")
        when "wishlist" then copy_vehicles(plan.user.vehicles.wanted.where(loaner: false, bundled: false))
        when "plan" then copy_plan
        end
        plan.update_columns(based_on_vehicle_ids: plan.live_vehicles.pluck(:id)) unless source == "plan"
        plan
      end
    end

    private def copy_vehicles(vehicles)
      vehicles = vehicles.includes(:model, :vehicle_paints, :vehicle_modules, :vehicle_upgrades).order(:created_at).to_a
      groups = vehicles.group_by do |vehicle|
        [vehicle.model_id, vehicle.vehicle_paints.first&.model_paint_id,
          vehicle.vehicle_modules.map(&:model_module_id).sort, vehicle.vehicle_upgrades.map(&:model_upgrade_id).sort]
      end

      ships = groups.flat_map { |fitting, group| group.map { |vehicle| [fitting, vehicle.model.name] } }
      return if ships.empty?

      check_slot_limit(ships.size)
      slot_ids = ships.map { SecureRandom.uuid }
      HangarPlanSlot.insert_all!(
        ships.each_with_index.map { |(_, label), position| {id: slot_ids[position], hangar_plan_id: plan.id, label:, position:} }
      )
      HangarPlanCandidate.insert_all!(
        ships.zip(slot_ids).map do |((model_id, model_paint_id, model_module_ids, model_upgrade_ids), _), slot_id|
          {hangar_plan_slot_id: slot_id, model_id:, model_paint_id:, model_module_ids:, model_upgrade_ids:}
        end
      )
      plan.touch
    end

    # Bulk inserts skip the slot's own check, so a wishlist too big for one
    # plan fails the way adding one slot too many does.
    private def check_slot_limit(count)
      return if plan.slots.count + count <= HangarPlanSlot::MAX_PER_PLAN

      slot = plan.slots.build
      slot.errors.add(:base, :slot_limit_reached, count: HangarPlanSlot::MAX_PER_PLAN)
      raise ActiveRecord::RecordInvalid, slot
    end

    # Routes and melts reference the user's own ships and pledges, so a copy
    # keeps them; they stay one-per-plan, which a copy is.
    private def copy_plan
      plan.update!(source_plan.slice(:starting_credit, :buyback_tokens, :vat_rate, :based_on_at, :based_on_vehicle_ids))

      source_plan.slots.includes(:starts, candidates: {acquisitions: :upgrade_steps}).each do |source_slot|
        # A plan split from slots that held several ships can be over the slot
        # limit already, and its copy is no bigger.
        slot = plan.slots.new(source_slot.slice(:label, :description, :filters, :position))
        slot.save!(validate: false)
        source_slot.starts.each { |start| copy_acquisition(start, slot:) }
        source_slot.candidates.each do |source_candidate|
          candidate = slot.candidates.create!(
            source_candidate.slice(:model_id, :model_paint_id, :model_module_ids, :model_upgrade_ids, :position)
          )
          source_candidate.acquisitions.each { |acquisition| copy_acquisition(acquisition, candidate:) }
        end
      end
      link_bundled_starts

      source_plan.melts.each do |melt|
        plan.melts.insert_all!([melt.slice(:vehicle_id, :model_id, :value_override, :value_snapshot)
          .merge(created_at: Time.current, updated_at: Time.current)])
      end

      marks = source_plan.vehicle_marks.map do |mark|
        mark.slice(:vehicle_id, :model_id, :mark).merge(created_at: Time.current, updated_at: Time.current)
      end
      plan.vehicle_marks.insert_all!(marks) if marks.any?
    end

    # Copied as they stand, validations included: a source ship the hangar no
    # longer has would otherwise fail a copy the user only asked to duplicate.
    private def copy_acquisition(source, holder)
      copies[source.id] = acquisition = plan.acquisitions.new(
        source.slice(:start_kind, :source_vehicle_id, :buyback_pledge_id, :start_model_id, :price_override, :price_snapshot,
          :uses_buyback_token)
          .merge(holder)
      )
      acquisition.save!(validate: false)
      bundled_sources[acquisition] = source.bundled_with_id if source.bundled_with_id

      source.upgrade_steps.each do |step|
        acquisition.upgrade_steps.new(
          step.slice(:source_kind, :from_model_id, :to_model_id, :hangar_pledge_item_id, :buyback_pledge_id,
            :position, :price_override, :price_snapshot, :uses_buyback_token).merge(hangar_plan: plan)
        ).save!(validate: false)
      end
    end

    # A bundled start goes with the copy of the start whose pledge it comes in,
    # which may be copied after it.
    private def link_bundled_starts
      bundled_sources.each do |acquisition, source_id|
        acquisition.update_columns(bundled_with_id: copies[source_id]&.id)
      end
    end

    private def copies = @copies ||= {}

    private def bundled_sources = @bundled_sources ||= {}
  end
end
