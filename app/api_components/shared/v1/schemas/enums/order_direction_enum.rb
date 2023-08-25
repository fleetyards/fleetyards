# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class OrderDirectionEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ["asc", "desc"]
          })
        end
      end
    end
  end
end
