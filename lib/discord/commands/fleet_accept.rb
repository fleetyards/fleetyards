# frozen_string_literal: true

require "discord/commands/fleet_request_decision"

module Discord
  module Commands
    class FleetAccept < FleetRequestDecision
      def self.decision
        JoinRequestDecision::ACCEPT
      end

      def self.done_key
        "accepted"
      end
    end
  end
end
