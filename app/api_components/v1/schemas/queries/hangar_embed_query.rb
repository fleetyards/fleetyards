# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarEmbedQuery
        include SchemaConcern

        schema({
          type: :array,
          items: {type: :string}
        })
      end
    end
  end
end
