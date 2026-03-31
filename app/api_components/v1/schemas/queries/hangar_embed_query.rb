# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarEmbedQuery
        include Rswag::SchemaComponents::Component

        schema({
          type: :array,
          items: {type: :string}
        })
      end
    end
  end
end
