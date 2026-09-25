# frozen_string_literal: true

require "discord/commands/fleet_request_decision"

module Discord
  module Commands
    class FleetDecline < FleetRequestDecision
      def self.decision
        JoinRequestDecision::DECLINE
      end

      def self.done_key
        "declined"
      end
    end
  end
end
