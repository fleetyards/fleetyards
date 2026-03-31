# frozen_string_literal: true

module Shared
  module V1
    module Parameters
      class PageParameter
        include Rswag::SchemaComponents::Component

        schema({
          name: :page,
          in: :query,
          schema: {
            type: :string,
            default: "1"
          },
          required: false
        })
      end
    end
  end
end
