# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Fleets
        module Options
          class FleetOption
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                fid: {type: :string},
                name: {type: :string},
                slug: {type: :string}
              },
              additionalProperties: false,
              required: %w[id fid name slug]
            })
          end
        end
      end
    end
  end
end
