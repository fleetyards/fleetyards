# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetInvitesList
        include OpenapiRuby::Components::Base

        # FleetMembersList is the paginated collection; GET /fleets/invites returns a
        # bare array of the same member records.

        schema({
          type: :array,
          items: ::V1::Schemas::Fleets::FleetMember
        })
      end
    end
  end
end
