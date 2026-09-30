# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The repair a broken component runs on its own: `time` seconds after it
      # breaks it comes back at `healthRatio` of its health, at most
      # `maxRepairs` times.
      class ComponentSelfRepair
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            time: {type: :number},
            healthRatio: {type: :number},
            maxRepairs: {type: :integer}
          },
          additionalProperties: false
        })
      end
    end
  end
end
