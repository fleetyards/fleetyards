# frozen_string_literal: true

module HangarPlans
  # Creates a plan, empty or filled from the hangar, the wishlist or another
  # plan. Ships that share a model and fitting become one slot with a quantity,
  # so a hangar of 30 Gladii does not need 30 slots.
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
        when "hangar" then copy_vehicles(plan.live_vehicles, keep: true)
        when "wishlist" then copy_vehicles(plan.user.vehicles.wanted.where(loaner: false, bundled: false), keep: false)
        when "plan" then copy_plan
        end
        plan
      end
    end

    def copy_vehicles(vehicles, keep:)
      vehicles = vehicles.includes(:model, :vehicle_paints, :vehicle_modules, :vehicle_upgrades).order(:created_at).to_a
      groups = vehicles.group_by do |vehicle|
        [vehicle.model_id, vehicle.vehicle_paints.first&.model_paint_id,
          vehicle.vehicle_modules.map(&:model_module_id).sort, vehicle.vehicle_upgrades.map(&:model_upgrade_id).sort]
      end

      groups.each do |(model_id, paint_id, module_ids, upgrade_ids), group|
        slot = plan.slots.create!(label: group.first.model.name, quantity: group.size)
        candidate = slot.candidates.create!(model_id:, model_paint_id: paint_id,
          model_module_ids: module_ids, model_upgrade_ids: upgrade_ids)
        next unless keep

        group.each do |vehicle|
          plan.acquisitions.create!(candidate:, start_kind: "owned", source_vehicle: vehicle)
        end
      end
    end

    # Routes and melts reference the user's own ships and pledges, so a copy
    # keeps them; they stay one-per-plan, which a copy is.
    private def copy_plan
      plan.update!(source_plan.slice(:starting_credit, :buyback_tokens, :vat_rate, :based_on_at))

      source_plan.slots.includes(candidates: {acquisitions: :upgrade_steps}).each do |source_slot|
        slot = plan.slots.create!(source_slot.slice(:label, :description, :filters, :quantity, :position))
        source_slot.candidates.each do |source_candidate|
          candidate = slot.candidates.create!(
            source_candidate.slice(:model_id, :model_paint_id, :model_module_ids, :model_upgrade_ids, :position)
          )
          source_candidate.acquisitions.each { |acquisition| copy_acquisition(acquisition, candidate) }
        end
      end

      source_plan.melts.each do |melt|
        plan.melts.insert_all!([melt.slice(:vehicle_id, :model_id, :value_override, :value_snapshot)
          .merge(created_at: Time.current, updated_at: Time.current)])
      end
    end

    # Copied as they stand, validations included: a source ship the hangar no
    # longer has would otherwise fail a copy the user only asked to duplicate.
    private def copy_acquisition(source, candidate)
      acquisition = plan.acquisitions.new(
        source.slice(:start_kind, :source_vehicle_id, :buyback_pledge_id, :start_model_id, :price_override, :price_snapshot,
          :uses_buyback_token)
          .merge(candidate:)
      )
      acquisition.save!(validate: false)

      source.upgrade_steps.each do |step|
        acquisition.upgrade_steps.new(
          step.slice(:source_kind, :from_model_id, :to_model_id, :hangar_pledge_item_id, :buyback_pledge_id,
            :position, :price_override, :price_snapshot, :uses_buyback_token).merge(hangar_plan: plan)
        ).save!(validate: false)
      end
    end
  end
end
