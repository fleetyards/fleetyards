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
            permanent: {type: :boolean},
            selfServiceUser: {type: :boolean},
            selfServiceFleet: {type: :boolean},
            percentageOfActors: {type: :number},
            percentageOfTime: {type: :number},
            groups: {type: :array, items: {type: :string}},
            actors: {type: :array, items: ::Admin::V1::Schemas::FeatureActor},

            # All four are null for a flag nothing has touched since the log
            # started -- `fullyOnSince` also whenever the flag is not currently
            # on for everyone.
            fullyOnSince: {type: [:string, :null], format: "date-time"},
            lastChangedAt: {type: [:string, :null], format: "date-time"},
            lastChangedBy: {type: [:string, :null]},
            lastChangedSource: {type: [:string, :null]}
          },
          additionalProperties: false,
          required: %w[name state permanent selfServiceUser selfServiceFleet percentageOfActors percentageOfTime groups actors fullyOnSince lastChangedAt lastChangedBy lastChangedSource]
        })
      end
    end
  end
end
