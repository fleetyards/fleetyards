# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetEventQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            titleCont: {type: :string},
            statusEq: {type: :string},
            categoryEq: {type: :string},
            s: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
