# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Feature
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            state: {type: :string},
            selfServiceUser: {type: :boolean},
            selfServiceFleet: {type: :boolean},
            percentageOfActors: {type: :number},
            percentageOfTime: {type: :number},
            groups: {type: :array, items: {type: :string}},
            actors: {type: :array, items: ::Admin::V1::Schemas::FeatureActor}
          },
          additionalProperties: false,
          required: %w[name state selfServiceUser selfServiceFleet percentageOfActors percentageOfTime groups actors]
        })
      end
    end
  end
end
