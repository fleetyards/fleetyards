# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetInviteUrlsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/FleetInviteUrl"}
        })
      end
    end
  end
end
