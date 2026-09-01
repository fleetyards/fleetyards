# frozen_string_literal: true

require "discord/commands/fleet_request_decision"

module Discord
  module Commands
    class FleetDecline < FleetRequestDecision
      def self.policy_rule
        :decline_request?
      end

      def self.done_key
        "declined"
      end

      private def apply(membership)
        membership.decline!
      end
    end
  end
end
