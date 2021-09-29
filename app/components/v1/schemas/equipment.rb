# frozen_string_literal: true

module V1
  module Schemas
    class Equipment < ::BaseSchema
      data_type :object

      property :id, {type: :string, format: :uuid}
      property :name, {type: :string}
      property :slug, {type: :string}
      property :description, {type: :string}
      property :grade, {type: :string}
      property :size, {type: :string}
      property :type, {type: :string}
      property :typeLabel, {type: :string}
      property :itemType, {type: :string}
      property :itemTypeLabel, {type: :string}
      property :weaponClass, {type: :string}
      property :weaponClassLabel, {type: :string}
      property :slot, {type: :string}
      property :slotLabel, {type: :string}
      property :damageReduction, {type: :string}
      property :rateOfFire, {type: :string}
      property :range, {type: :string}
      property :extras, {type: :string}
      property :storage, {type: :string}
      property :storeImageIsFallback, {type: :boolean}
      property :storeImage, {type: :string}
      property :storeImageLarge, {type: :string}
      property :storeImageMedium, {type: :string}
      property :storeImageSmall, {type: :string}

      property :soldAt, {"$ref" => "#/components/schemas/ShopCommodity", :nullable => true}
      property :boughtAt, {"$ref" => "#/components/schemas/ShopCommodity", :nullable => true}
      property :manufacturer, {"$ref" => "#/components/schemas/Manufacturer", :nullable => true}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[id name slug storeImageIsFallback createdAt updatedAt]
    end
  end
end
