# frozen_string_literal: true

module Shared
  module V1
    module Parameters
      class SortingParameter
        include SchemaConcern

        schema({
          name: :s,
          in: :query,
          schema: {
            type: :array,
            items: {
              type: :string
            }
          },
          description: "Sorting",
          required: false
        })
      end
    end
  end
end
