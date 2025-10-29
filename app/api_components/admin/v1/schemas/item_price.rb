# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ItemPrice < ::V1::Schemas::ItemPrice
        include SchemaConcern

        schema({
          properties: {}
        })
      end
    end
  end
end
