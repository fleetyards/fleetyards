# frozen_string_literal: true

module V1
  module Schemas
    class CommodityPrice < ::BaseSchema
      data_type :object

      property :id, {type: :string, format: :uuid}
      property :price, {type: :number, format: :float}
      property :timeRange, {type: :string, nullable: true}
      property :type, {type: :string}
      property :shopCommodityId, {type: :string, format: :uuid}
      property :confirmed, {type: :boolean}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[id price type shop_commodity_id confirmed createdAt updatedAt]
    end
  end
end
