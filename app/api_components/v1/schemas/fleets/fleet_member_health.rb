# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # Every check on the member health page. A check that is null does not
      # apply to this fleet, or the reader may not see it.
      class FleetMemberHealth
        include OpenapiRuby::Components::Base

        section = ::V1::Schemas::Fleets::FleetMemberHealthSection
        nullable = ->(ref, description) { {anyOf: [ref, {type: :null}], description:} }

        schema({
          type: :object,
          properties: {
            inactiveDays: {type: :integer},
            inactiveSince: {type: :string, format: :date, description: "The day inactiveMembers counts from, for the members list's inactiveSince filter"},
            requestedBefore: {type: :string, format: :date, description: "The day waitingJoinRequests counts up to, for the members list's requestedAtLteq filter"},
            invitedBefore: {type: :string, format: :date, description: "The day unansweredInvitations counts up to, for the members list's invitedAtLteq filter"},
            fleetRsiVerified: {type: :boolean},
            rsiMemberCount: {type: [:integer, :null], description: "Members of the fleet's RSI org on RSI; null without an RSI SID"},
            memberCount: {type: :integer},
            hiddenShipsCount: {type: :integer, description: "Members who keep their ships out of the fleet"},
            admins: ::V1::Schemas::Fleets::FleetMemberHealthAdmins,
            unverifiedMembers: nullable.call(section, "Null when the fleet has no RSI SID"),
            membersWithoutRsiHandle: nullable.call(section, "Null when the fleet has an RSI SID"),
            inactiveMembers: section,
            waitingJoinRequests: section,
            unansweredInvitations: section,
            staleInviteUrls: nullable.call(::V1::Schemas::Fleets::FleetMemberHealthInviteUrls, "Null when the reader cannot read invites"),
            membersWithoutDiscord: nullable.call(section, "Null unless the fleet hands out Discord roles"),
            membersWithoutSquadron: nullable.call(section, "Null unless squadrons are on and the reader can read them"),
            emptySquadrons: nullable.call(::V1::Schemas::Fleets::FleetMemberHealthSquadrons, "Null unless squadrons are on and the reader can read them")
          },
          required: %w[inactiveDays inactiveSince requestedBefore invitedBefore fleetRsiVerified rsiMemberCount memberCount hiddenShipsCount admins
            unverifiedMembers membersWithoutRsiHandle inactiveMembers waitingJoinRequests unansweredInvitations
            staleInviteUrls membersWithoutDiscord membersWithoutSquadron emptySquadrons],
          additionalProperties: false
        })
      end
    end
  end
end
