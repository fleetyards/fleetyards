# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetSquadronSortEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: FleetSquadron::ALLOWED_SORTING_PARAMS,
          "x-enumNames": FleetSquadron::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
