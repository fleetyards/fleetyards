# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelClassificationEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Model.classifications
          })
        end
      end
    end
  end
end
