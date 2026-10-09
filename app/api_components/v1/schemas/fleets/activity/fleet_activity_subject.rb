# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Activity
        # What an entry is about. `slug` is what a link to it needs, where the
        # subject has a page of its own: a member's username, an event's or a
        # contract's slug.
        class FleetActivitySubject
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              type: ::V1::Schemas::Enums::FleetActivitySubjectTypeEnum,
              id: {type: :string, format: :uuid},
              slug: {type: [:string, :null]},
              title: {type: [:string, :null]}
            },
            required: %w[type id slug title]
          })
        end
      end
    end
  end
end
