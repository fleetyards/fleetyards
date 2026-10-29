# frozen_string_literal: true

module HangarPlans
  # What else the pledges of the given hangar ships hold: their other ships and
  # the paints, flair, gear and upgrades the hangar sync read. Melting one ship
  # of a pledge melts all of it.
  class PledgeContents
    Contents = Data.define(:name, :ships, :items)

    EMPTY = Contents.new(name: nil, ships: [], items: [])

    def initialize(plan, vehicles)
      pledges = vehicles.filter_map(&:rsi_pledge_id).uniq
      @ships = @items = {}
      return if pledges.empty?

      @ships = plan.live_vehicles.where(rsi_pledge_id: pledges)
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

      Contents.new(name:, ships: @ships.fetch(pledge, []) - [vehicle], items:)
    end
  end
end
