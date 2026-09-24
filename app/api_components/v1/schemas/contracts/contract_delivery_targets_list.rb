# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class ContractDeliveryTargetsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Contracts::ContractDeliveryTarget
        })
      end
    end
  end
end
