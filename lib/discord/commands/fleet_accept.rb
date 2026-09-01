# frozen_string_literal: true

require "discord/commands/fleet_request_decision"

module Discord
  module Commands
    class FleetAccept < FleetRequestDecision
      def self.policy_rule
        :accept_request?
      end

      def self.done_key
        "accepted"
      end

      # The AASM event carries the rest: it notifies the new member and
      # broadcasts the hangar change to everyone already in the fleet.
      private def apply(membership)
        membership.accept_request!
      end
    end
  end
end
