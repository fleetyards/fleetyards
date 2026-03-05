# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelUpgradeQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              idEq: {type: :string, format: :uuid},
              nameCont: {type: :string},
              nameEq: {type: :string},
              upgradeKitsModelIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
