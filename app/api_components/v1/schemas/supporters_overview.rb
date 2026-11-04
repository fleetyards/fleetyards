# frozen_string_literal: true

module V1
  module Schemas
    # Everyone who agreed to be named across every month, and how many more did
    # not. Unpaginated on purpose: the page reads it as one list, and naming is
    # opt-in, so it stays far smaller than the number of payments behind it.
    class SupportersOverview
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          supporters: {
            type: :array,
            items: ::V1::Schemas::Supporter
          },
          anonymousCount: {type: :integer}
        },
        additionalProperties: false,
        required: %w[supporters anonymousCount]
      })
    end
  end
end
