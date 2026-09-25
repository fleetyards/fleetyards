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

    # :done, :not_pending or :failed.
    #
    # Two officers answering the same request is normal, not an error -- every
    # officer sees the same buttons, and a double-click is two interactions.
    # The state is read again under a row lock: both copies would otherwise
    # still read `requested`, both transitions would save, and a request could
    # end up declined after its applicant was told they were accepted.
    def call
      return :not_pending unless membership.requested?

      membership.with_lock do
        if membership.requested?
          # Recorded on the version, so the audit trail names the officer
          # rather than nobody.
          membership.author_id = officer.id

          apply ? :done : :failed
        else
          :not_pending
        end
      end
    end

    # The AASM events carry the rest: accepting notifies the new member and
    # broadcasts the hangar change to everyone already in the fleet.
    private def apply
      case decision
      when ACCEPT then membership.accept_request!
      when DECLINE then membership.decline!
      else raise ArgumentError, "unknown decision #{decision.inspect}"
      end
    end
  end
end
