# frozen_string_literal: true

# What the site search offers from a user's own hangar, one group per list the
# hangar has. The scopes come from the controller, authorized.
class HangarSearch
  PLEDGE_KINDS = {
    "Paint" => :paints,
    "Flair" => :flair,
    "PledgeEquipment" => :equipment,
    "PledgeComponent" => :ship_components,
    "Upgrade" => :upgrades
  }.freeze

  # `online` answers for one friend, by the rule that goes for the reader.
  def initialize(vehicles:, wishlist:, friends:, blueprints:, inventory_items:, pledge_items:, buybacks:, online:)
    @vehicles = vehicles
    @wishlist = wishlist
    @friends = friends
    @online = online
    @blueprints = blueprints
    @inventory_items = inventory_items
    @pledge_items = pledge_items
    @buybacks = buybacks
  end

  def call(query)
    ScopedSearch.new(sources).call(query)
  end

  private def sources
    [
      vehicle_source("HangarVehicle", @vehicles),
      vehicle_source("WishlistVehicle", @wishlist),
      ScopedSearch::Source.new(
        type: "Friend",
        scope: @friends.with_attached_avatar.order(:username),
        filter: :username_or_display_name_cont,
        item: lambda { |friend|
          ScopedSearch.result(
            type: "User",
            name: friend.username,
            slug: friend.username,
            detail: friend.display_name.presence,
            image: friend.avatar.attached? ? friend.avatar : nil,
            online: @online.call(friend)
          )
        }
      ),
      ScopedSearch::Source.new(
        type: "OwnedBlueprint",
        scope: @blueprints.order(Arel.sql(::Catalogue::TokenResolver.name_sql("blueprint"))),
        filter: :name_cont,
        item: ->(blueprint) { ScopedSearch.result(type: "Blueprint", name: blueprint.name, slug: blueprint.slug) }
      ),
      ScopedSearch::Source.new(
        type: "InventoryItem",
        scope: @inventory_items.includes(:inventory).order(:name),
        filter: :name_cont,
        item: lambda { |item|
          ScopedSearch.result(type: "InventoryItem", name: item.name, slug: item.id, detail: item.inventory.name)
        }
      ),
      *PLEDGE_KINDS.map { |type, kind| named_source(type, @pledge_items.public_send(kind)) },
      named_source("Buyback", @buybacks)
    ]
  end

  private def vehicle_source(type, scope)
    ScopedSearch::Source.new(
      type:,
      scope: scope.includes(:model).references(:model).order("models.name", :name),
      filter: :search_cont,
      item: lambda { |vehicle|
        ScopedSearch.result(
          type: "Vehicle",
          name: vehicle.display_name,
          slug: vehicle.id,
          detail: vehicle.name.present? ? vehicle.model.name : nil
        )
      }
    )
  end

  private def named_source(type, scope)
    ScopedSearch::Source.new(
      type:,
      scope: scope.order(:name),
      filter: :name_cont,
      item: ->(record) { ScopedSearch.result(type:, name: record.name, slug: record.id) }
    )
  end
end
