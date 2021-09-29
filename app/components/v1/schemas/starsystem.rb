# frozen_string_literal: true

module V1
  module Schemas
    class Starsystem < ::BaseSchema
      data_type :object

      property :name, {type: :string}
      property :slug, {type: :string}
      property :storeImage, {type: :string}
      property :storeImageLarge, {type: :string}
      property :storeImageMedium, {type: :string}
      property :storeImageSmall, {type: :string}
      property :mapX, {type: :string, nullable: true}
      property :mapY, {type: :string, nullable: true}
      property :description, {type: :string, nullable: true}
      property :type, {type: :string, nullable: true}
      property :size, {type: :string, nullable: true}
      property :population, {type: :string, nullable: true}
      property :economy, {type: :string, nullable: true}
      property :danger, {type: :string, nullable: true}
      property :status, {type: :string, nullable: true}
      property :locationLabel, {type: :string, nullable: true}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[name slug createdAt updatedAt]
    end
  end
end
