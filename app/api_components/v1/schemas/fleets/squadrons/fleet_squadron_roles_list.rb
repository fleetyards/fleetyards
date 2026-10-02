# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronRolesList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Fleets::Squadrons::FleetSquadronRole
          })
        end
      end
    end
  end
end
