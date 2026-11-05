# frozen_string_literal: true

module HangarPlans
  # What else the pledges of the given hangar ships hold: their other ships and
  # the paints, flair, gear and upgrades the hangar sync read. Melting one ship
  # of a pledge melts all of it.
  class PledgeContents
    # `standalone` is nil where the hangar sync never saw the ship's pledge.
    Contents = Data.define(:name, :ships, :items, :standalone)

    EMPTY = Contents.new(name: nil, ships: [], items: [], standalone: nil)

    STANDALONE_NAME = /\Astandalone/i
    PACKAGE_NAME = /\Apackage/i

    def initialize(plan, vehicles)
      pledges = vehicles.filter_map(&:rsi_pledge_id).uniq
      @ships = @items = {}
      return if pledges.empty?

      @ships = plan.pledged_vehicles.where(rsi_pledge_id: pledges)
        .includes(model: MODEL_PRELOAD).order(:created_at).group_by(&:rsi_pledge_id)
      @items = plan.user.hangar_pledge_items.where(rsi_pledge_id: pledges)
        .order(:kind, :name).group_by(&:rsi_pledge_id)
    end

    def for(vehicle)
      pledge = vehicle&.rsi_pledge_id
      return EMPTY if pledge.nil?

      items = @items.fetch(pledge, [])
      # Ships synced before the pledge name was kept still find it on an item
      # of the same pledge.
      name = vehicle.rsi_pledge_name.presence || items.filter_map(&:pledge_name).first

      ships = @ships.fetch(pledge, []) - [vehicle]

      Contents.new(name:, ships:, items:, standalone: standalone?(vehicle, name, ships, items))
    end

    # RSI sells a "Standalone Ship - Pulse plus Dominion Paint", so what else a
    # pledge holds besides ships only tells where its name does not.
    private def standalone?(vehicle, name, ships, items)
      return false if ships.any? || items.any? && !STANDALONE_NAME.match?(name.to_s) || PACKAGE_NAME.match?(name.to_s)
      return true if STANDALONE_NAME.match?(name.to_s)
      return if vehicle.rsi_pledge_item_count.nil?

      vehicle.rsi_pledge_item_count <= 1
    end
  end
end
