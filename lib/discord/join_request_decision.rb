# frozen_string_literal: true

module Discord
  # Settles one join request on behalf of a linked officer. The slash commands
  # and the buttons on the join-request message both land here, so the two
  # cannot drift apart on who may answer or on what answering records.
  class JoinRequestDecision
    ACCEPT = "accept"
    DECLINE = "decline"

    # The same policy rules the members endpoint authorizes against. Both
    # require an accepted, undiscarded membership of the fleet.
    RULES = {ACCEPT => :accept_request?, DECLINE => :decline_request?}.freeze

    DECISIONS = RULES.keys.freeze

    def self.allowed?(decision, fleet, user)
      ::FleetMembershipPolicy.new(fleet, user: user).apply(RULES.fetch(decision))
    end

    attr_reader :decision, :membership, :officer

    def initialize(decision, membership, officer:)
      @decision = decision
      @membership = membership
      @officer = officer
    end

    # :done, :not_pending or :failed. The early exit is only a shortcut; the
    # state that counts is read again under the lock.
    #
    # Two officers answering the same request is normal, not an error -- every
    # officer sees the same buttons, and a double-click is two interactions.
    # Recording the officer puts their name on the version, so the audit trail
    # and the settled message both say who answered.
    def call
      return :not_pending unless membership.requested?

      membership.answer_request(accept: decision == ACCEPT, author_id: officer.id)
    end
  end
end
