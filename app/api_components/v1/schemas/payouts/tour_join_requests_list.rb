# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class TourJoinRequestsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: TourJoinRequest
        })
      end
    end
  end
end
