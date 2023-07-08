# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class StationQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              searchCont: {type: :string, nullable: true},
              nameCont: {type: :string, nullable: true},
              nameIn: {type: :array, items: {type: :string}, nullable: true}
            }
          })
        end
      end
    end
  end
end
