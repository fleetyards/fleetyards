# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class BoughtViaEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::Vehicle.bought_via.keys
        })
      end
    end
  end
end
