# frozen_string_literal: true

module V1
  module Schemas
    class CelestialObject < CelestialObjectBase
      data_type :object

      property :starsystem, {"$ref" => "#/components/schemas/Starsystem"}
      property :parent, {"$ref" => "#/components/schemas/CelestialObjectBase", :nullable => true}
      property :moons, {type: :array, items: {"$ref" => "#/components/schemas/CelestialObjectBase"}}

      required %w[starsystem]
    end
  end
end
