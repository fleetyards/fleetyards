# frozen_string_literal: true

module HangarPlans
  # What the user owns that a plan can spend: hangar ships, unapplied upgrades
  # from the RSI hangar and buy-back pledges, each with how much of it the plan
  # already uses.
  class Resources
    USES = %w[acquisition melt].freeze

    VehicleResource = Data.define(:vehicle, :used_by)
    UpgradeResource = Data.define(:item, :from_model, :to_model, :used_count)
    BuybackResource = Data.define(:pledge, :used)

    UPGRADE_NAME = /\A(?:Upgrade\s*-\s*)?(.+?)\s+to\s+(.+)\z/i
    SALE_SUFFIX = /\s+(-\s*)?(warbond(\s+edition)?|standard\s+edition|best\s+in\s+show(\s+edition)?(\s+\d{4})?)\z/i

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def vehicles
      routes = plan.acquisitions.where.not(source_vehicle_id: nil).pluck(:source_vehicle_id).to_set
      melts = plan.melts.pluck(:vehicle_id).to_set

      plan.live_vehicles.includes(model: MODEL_PRELOAD).order(:created_at).map do |vehicle|
        used_by = if routes.include?(vehicle.id)
          "acquisition"
        elsif melts.include?(vehicle.id)
          "melt"
        end
        VehicleResource.new(vehicle:, used_by:)
      end
    end

    def upgrades
      items = plan.user.hangar_pledge_items.upgrades.order(HangarPledgeItem.hangar_order).to_a
      used = plan.upgrade_steps.where.not(hangar_pledge_item_id: nil).group(:hangar_pledge_item_id).count
      models = models_by_name(items.flat_map { |item| upgrade_names(item.name) })

      items.map do |item|
        from, to = upgrade_names(item.name)
        UpgradeResource.new(item:, from_model: models[from], to_model: models[to], used_count: used.fetch(item.id, 0))
      end
    end

    def buybacks
      used = (plan.acquisitions.where.not(buyback_pledge_id: nil).pluck(:buyback_pledge_id) +
        plan.upgrade_steps.where.not(buyback_pledge_id: nil).pluck(:buyback_pledge_id)).to_set

      plan.user.buyback_pledges.where(kind: HangarPlanAcquisition::BUYBACK_SHIP_KINDS + ["upgrade"])
        .includes(upgrade_from_model: MODEL_PRELOAD, upgrade_to_model: MODEL_PRELOAD).order(reclaimed_on: :desc, name: :asc)
        .map { |pledge| BuybackResource.new(pledge:, used: used.include?(pledge.id)) }
    end

    # The two ship names an RSI upgrade title carries, downcased, with how the
    # upgrade was sold taken off the target.
    private def upgrade_names(name)
      match = UPGRADE_NAME.match(name.to_s.squish)
      return [] if match.nil?

      [match[1], match[2].sub(SALE_SUFFIX, "")].map { |part| part.strip.downcase }
    end

    private def models_by_name(names)
      return {} if names.empty?

      aliases = Rsi::ShipNames::MAPPING.to_h { |rsi_name, name| [rsi_name.downcase, name.downcase] }
      lookup = names.uniq.index_with { |name| aliases.fetch(name, name) }
      found = Model.visible.active.includes(MODEL_PRELOAD).where("lower(models.name) IN (:names) OR lower(models.rsi_name) IN (:names)", names: lookup.values.uniq).to_a

      lookup.transform_values do |name|
        found.find { |model| model.name.downcase == name } || found.find { |model| model.rsi_name&.downcase == name }
      end
    end
  end
end
