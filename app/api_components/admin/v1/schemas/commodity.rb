# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Commodity < ::V1::Schemas::Commodity
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            # `buyPrice` and `sellPrice` are inherited rather than declared
            # here: the public payload carries them too now, and a duplicate
            # definition in this subclass would quietly win over the parent's
            # the next time the public one changes.
            uexId: {type: [:integer, :null]},
            uexCode: {type: [:string, :null]},
            scKey: {type: [:string, :null]},
            scRef: {type: [:string, :null]},
            version: {type: [:string, :null]}
          }
        })
      end
    end
  end
end
