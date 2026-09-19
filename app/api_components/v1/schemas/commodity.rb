# frozen_string_literal: true

module V1
  module Schemas
    class Commodity
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          commodityType: {type: [:string, :null]},
          description: {type: [:string, :null]},

          # Whether the game hands this commodity out a piece at a time rather
          # than hauling it in bulk. Says which units an inventory may record it
          # in, and the crafting pages need it to compare a holding with what a
          # recipe asks for.
          counted: {type: :boolean},

          # What one piece takes up, in SCU, for a counted commodity. Null for
          # the bulk ones: theirs is a crate, sold in seven sizes, so there is
          # no single figure to state.
          pieceVolume: {type: [:number, :null]},

          # Whether a player can eat or drink it. Ten of the catalogue: nine
          # harvestables you pick and eat, and SLAM.
          consumable: {type: :boolean},

          # Every size it is packaged in, in SCU -- the hand-carried forms below
          # one, then the freight crates up to 32. Empty for the refuel and
          # rearm goods, which no crate entity declares.
          containerSizes: {type: :array, items: {type: :number}},

          # The refined good an ore or raw form becomes, where it becomes one.
          refinesInto: ::Shared::V1::Schemas::CommodityRef,

          # Whether the build we are on still describes this commodity. Until now
          # the API served one the export had dropped as though it were current.
          retired: {type: :boolean},
          storeImage: ::Shared::V1::Schemas::MediaFile,

          # The UEX snapshot prices commodities at every terminal that trades
          # them, which is the whole point of syncing it -- the same shape the
          # component and equipment payloads carry.
          availability: Shared::V1::Schemas::ItemAvailability,

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name slug counted retired availability createdAt updatedAt]
      })
    end
  end
end
