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

    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def vehicles
      routes = plan.acquisitions.where.not(source_vehicle_id: nil).pluck(:source_vehicle_id).to_set
      melts = plan.melted_vehicle_ids.to_set

      vehicles = plan.live_vehicles.includes(model: MODEL_PRELOAD).order(:created_at).to_a
      pledges = PledgeContents.new(plan, vehicles)

      vehicles.map do |vehicle|
        used_by = if routes.include?(vehicle.id)
          "acquisition"
        elsif melts.include?(vehicle.id)
          "melt"
        end
        contents = pledges.for(vehicle)

        VehicleResource.new(vehicle:, used_by:, pledge_name: contents.name, pledge_ships: contents.ships, pledge_items: contents.items)
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
    # plan with. So are ships no player can own and those only earned in game,
    # which the store never sells.
    def store_models
      Model.visible.active.where(player_ownable: true, ingame_only: false).where.not(pledge_price: nil)
        .includes(:manufacturer).order(:pledge_price, :name)
    end

    def buybacks
      used = (plan.acquisitions.where.not(buyback_pledge_id: nil).pluck(:buyback_pledge_id) +
        plan.upgrade_steps.where.not(buyback_pledge_id: nil).pluck(:buyback_pledge_id)).to_set

      pledges = plan.user.buyback_pledges.where(kind: BUYBACK_KINDS)
        .includes(upgrade_from_model: MODEL_PRELOAD, upgrade_to_model: MODEL_PRELOAD).order(reclaimed_on: :desc, name: :asc).to_a
      names = pledges.to_h { |pledge| [pledge.id, pledge.returned_ship_names] }
      models = models_by_name(names.values.flatten)

      pledges.map do |pledge|
        ships = names[pledge.id].filter_map { |name| models[name] }.uniq
        BuybackResource.new(pledge:, models: ships, used: used.include?(pledge.id))
      end
    end

    private def upgrade_names(name) = Rsi::UpgradeTitles.ship_names(name)

    private def models_by_name(names) = Rsi::UpgradeTitles.models_by_name(names, preload: MODEL_PRELOAD)
  end
end
