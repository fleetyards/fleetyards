# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Dashboard
        # A page of who is online, with how many are in all: the list is cut
        # short for a panel, and the count says by how much.
        class FleetOnlineMembersList
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              totalCount: {type: :integer},
              items: {
                type: :array,
                items: ::V1::Schemas::Fleets::Dashboard::FleetOnlineMember
              }
            },
            required: %w[totalCount items]
          })
        end
      end
    end
  end
end
