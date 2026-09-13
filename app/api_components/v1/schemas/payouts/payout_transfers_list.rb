# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutTransfersList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: PayoutTransfer
        })
      end
    end
  end
end
