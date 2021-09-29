# frozen_string_literal: true

module V1
  module Schemas
    class Commodity < ::BaseSchema
      data_type :object

      property :id, {type: :string, format: :uuid}
      property :name, {type: :string}
      property :slug, {type: :string}
      property :type, {type: :string}
      property :typeLabel, {type: :string}
      property :storeImageIsFallback, {type: :boolean}
      property :storeImage, {type: :string}
      property :storeImageLarge, {type: :string}
      property :storeImageMedium, {type: :string}
      property :storeImageSmall, {type: :string}

      property :soldAt, {"$ref" => "#/components/schemas/ShopCommodity", :nullable => true}
      property :boughtAt, {"$ref" => "#/components/schemas/ShopCommodity", :nullable => true}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[id name slug storeImageIsFallback createdAt updatedAt]
    end
  end
end
