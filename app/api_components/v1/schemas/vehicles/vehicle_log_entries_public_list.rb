# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLogEntriesPublicList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Vehicles::VehicleLogEntryPublic
        })
      end
    end
  end
end
