# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Station < ::V1::Schemas::Station
        include SchemaConcern

        schema({
          properties: {
            id: {type: :string, format: :uuid}
          },
          required: %w[id]
        })
      end
    end
  end
end
