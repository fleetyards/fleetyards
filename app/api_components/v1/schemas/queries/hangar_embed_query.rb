# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarEmbedQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {type: :string}
        })
      end
    end
  end
end
