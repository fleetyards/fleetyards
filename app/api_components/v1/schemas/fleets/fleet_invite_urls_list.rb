# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetInviteUrlsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Fleets::FleetInviteUrl
        })
      end
    end
  end
end
