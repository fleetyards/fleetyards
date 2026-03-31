# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ComponentQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              itemTypeCont: {type: :string},
              componentClassCont: {type: :string},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},
              itemTypeIn: {type: :array, items: {type: :string}},
              componentClassIn: {type: :array, items: {type: :string}},
              manufacturerIdIn: {type: :array, items: {type: :string, format: :uuid}}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
