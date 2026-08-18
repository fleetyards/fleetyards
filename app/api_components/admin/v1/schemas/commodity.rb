# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Commodity < ::V1::Schemas::Commodity
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            # The cheapest UEX quote of each direction. A commodity is priced at
            # every terminal that trades it, so the list carries the two numbers
            # rather than the hundreds of rows behind them.
            buyPrice: {type: [:number, :null]},
            sellPrice: {type: [:number, :null]},

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
