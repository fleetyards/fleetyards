# frozen_string_literal: true

module V1
  module Schemas
    class CelestialObjectBase < ::BaseSchema
      data_type :object

      property :name, {type: :string}
      property :slug, {type: :string}
      property :designation, {type: :string}
      property :storeImageIsFallback, {type: :boolean}
      property :storeImage, {type: :string, format: :url}
      property :storeImageLarge, {type: :string}
      property :storeImageMedium, {type: :string}
      property :storeImageSmall, {type: :string}
      property :description, {type: :string, nullable: true}
      property :type, {type: :string, nullable: true}
      property :habitable, {type: :boolean, nullable: true}
      property :fairchanceact, {type: :boolean, nullable: true}
      property :subType, {type: :string, nullable: true}
      property :size, {type: :string, nullable: true}
      property :danger, {type: :integer, nullable: true}
      property :economy, {type: :integer, nullable: true}
      property :population, {type: :integer, nullable: true}
      property :locationLabel, {type: :string, nullable: true}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[name slug designation createdAt updatedAt]
    end
  end
end
