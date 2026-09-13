# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutParticipantsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: PayoutParticipant
        })
      end
    end
  end
end
