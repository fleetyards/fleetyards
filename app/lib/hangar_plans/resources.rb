# frozen_string_literal: true

module HangarPlans
  # What the user owns that a plan can spend: hangar ships, unapplied upgrades
  # from the RSI hangar and buy-back pledges, each with how much of it the plan
  # already uses; and the store's ships, which anyone can buy.
  class Resources
    USES = %w[acquisition melt].freeze

    VehicleResource = Data.define(:vehicle, :used_by, :pledge_name, :pledge_ships, :pledge_items)
    UpgradeResource = Data.define(:item, :from_model, :to_model, :used_count)
    BuybackResource = Data.define(:pledge, :models, :used)

    # What a route can buy back: a standalone ship or a package to start from,
    # or an upgrade to take a step with. Paints, add-ons and the rest hold no
    # ship to plan with.
    BUYBACK_KINDS = %w[ship package upgrade].freeze

    UPGRADE_NAME = /\A(?:Upgrade\s*-\s*)?(.+?)\s+to\s+(.+)\z/i
    SALE_SUFFIX = /\s+(-\s*)?(warbond(\s+edition)?|standard\s+edition|best\s+in\s+show(\s+edition)?(\s+\d{4})?)\z/i
    STANDALONE_PREFIX = /\AStandalone\s+Ships?\s+-\s+/i
    TITLE_SUFFIX = /\s+(-|–|plus)\s+.*\z/i
    CONTAINED_SUFFIX = /\s+and\s+(\d+\s|lifetime\s+insurance).*\z/i

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def vehicles
      routes = plan.acquisitions.where.not(source_vehicle_id: nil).pluck(:source_vehicle_id).to_set
      melts = plan.melts.pluck(:vehicle_id).to_set

      vehicles = plan.live_vehicles.includes(model: MODEL_PRELOAD).order(:created_at).to_a
      ships = vehicles.select { |vehicle| vehicle.rsi_pledge_id.present? }.group_by(&:rsi_pledge_id)
      items = plan.user.hangar_pledge_items.where(rsi_pledge_id: ships.keys)
        .order(:kind, :name).group_by(&:rsi_pledge_id)

      vehicles.map do |vehicle|
        used_by = if routes.include?(vehicle.id)
          "acquisition"
        elsif melts.include?(vehicle.id)
          "melt"
        end
        pledge_ships = vehicle.rsi_pledge_id ? ships.fetch(vehicle.rsi_pledge_id) - [vehicle] : []
        pledge_items = items.fetch(vehicle.rsi_pledge_id, [])
        # Ships synced before the pledge name was kept still find it on an item
        # of the same pledge.
        pledge_name = vehicle.rsi_pledge_name.presence || pledge_items.filter_map(&:pledge_name).first

        VehicleResource.new(vehicle:, used_by:, pledge_name:, pledge_ships:, pledge_items:)
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

    # Every ship the pledge store prices, for a route that buys its start or an
    # upgrade there. Unpriced ships are left out: the store has no figure to
    # plan with.
    def store_models
      Model.visible.active.where.not(pledge_price: nil).includes(:manufacturer).order(:pledge_price, :name)
    end

    def buybacks
      used = (plan.acquisitions.where.not(buyback_pledge_id: nil).pluck(:buyback_pledge_id) +
        plan.upgrade_steps.where.not(buyback_pledge_id: nil).pluck(:buyback_pledge_id)).to_set

      pledges = plan.user.buyback_pledges.where(kind: BUYBACK_KINDS)
        .includes(upgrade_from_model: MODEL_PRELOAD, upgrade_to_model: MODEL_PRELOAD).order(reclaimed_on: :desc, name: :asc).to_a
      names = pledges.to_h { |pledge| [pledge.id, ship_names(pledge)] }
      models = models_by_name(names.values.flatten)

      pledges.map do |pledge|
        ships = names[pledge.id].filter_map { |name| models[name] }.uniq
        BuybackResource.new(pledge:, models: ships, used: used.include?(pledge.id))
      end
    end

    # The ships a buy-back returns, by the names its detail page lists, else its
    # contents line, else a standalone ship's title. An upgraded pledge comes
    # back as first bought, so its contents line, which names the upgrade's
    # target, is skipped. Mirrors `BuybackPledge.obtaining_model`.
    private def ship_names(pledge)
      return [] if pledge.kind == "upgrade"

      names = Array(pledge.ship_names).compact_blank
      names = [pledge.contained.sub(CONTAINED_SUFFIX, "")] if names.empty? && pledge.contained.present? && !pledge.upgraded
      if names.empty? && pledge.kind == "ship"
        names = [pledge.name.sub(STANDALONE_PREFIX, "").sub(TITLE_SUFFIX, "")]
      end

      names.map { |name| name.squish.downcase }.compact_blank
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
