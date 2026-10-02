# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronRoleUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            # Only ever true: the default moves to this rank. It cannot be
            # cleared, because new members always need one to start on.
            defaultRank: {type: :boolean, enum: [true]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
