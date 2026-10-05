# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FeatureActor
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: {type: :string},
            id: {type: :string},
            name: {type: :string},
            fid: {type: [:string, :null], description: "The fleet's SID, for a fleet actor"}
          },
          additionalProperties: false,
          required: %w[type id name fid]
        })
      end
    end
  end
end
