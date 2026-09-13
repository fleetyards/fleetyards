# frozen_string_literal: true

module Relationships
  # Answering a request, calling one back, or ending a relationship.
  #
  # The state is re-read under a row lock rather than trusted from the instance
  # the controller loaded. `whiny_transitions: false` means a transition that
  # loses a race returns false *after* deciding it was legal, so two requests
  # can both read `pending` and both believe they answered. Nothing here writes
  # a ledger, so a lost race costs no data -- but the caller still has to be
  # told the truth about which answer stuck.
  class Answerer
    include ActiveModel::Model

    attr_reader :relationship

    def initialize(relationship, actor:)
      @relationship = relationship
      @actor = actor
    end

    # `party` is the side being answered *for*: the user themselves, or the
    # fleet an admin is acting on behalf of. The privilege behind that stands
    # in the policy; what this checks is that the party is actually one end of
    # this relationship.
    def accept(party) = answer(:accept!, party)

    def decline(party) = answer(:decline!, party)

    def ignore(party) = answer(:ignore!, party)

    # The sender calling it back before it was answered. The row goes, rather
    # than moving to a state -- an unsent request is not a refusal, and leaving
    # one behind would make the pair unrequestable until somebody cleared it.
    def cancel(party)
      apply do
        unless @relationship.cancellable_by?(party)
          errors.add(:base, :forbidden)
          next
        end

        # An ignored row answers as though it were cancelled and is left
        # standing. Destroying it would hand the requester a way to clear an
        # ignore and ask again, which is the one thing ignoring is for.
        next if @relationship.ignored?

        @relationship.destroy!
      end
    end

    # Either side ending an accepted relationship. Destroyed for the same
    # reason, and so the pair can be asked again later.
    def end_relationship(party)
      apply do
        unless @relationship.accepted? && @relationship.involves?(party)
          errors.add(:base, :forbidden)
          next
        end

        @relationship.destroy!
      end
    end

    private def answer(event, party)
      apply do
        unless @relationship.answerable_by?(party)
          errors.add(:base, :forbidden)
          next
        end

        # Checked rather than assumed: `whiny_transitions: false` returns
        # false from a refused transition instead of raising, so an unchecked
        # call reports success for an answer that never landed.
        next if @relationship.public_send(event)

        errors.add(:base, :already_resolved)
      end
    end

    private def apply
      ::ActiveRecord::Base.transaction do
        @relationship.lock!
        yield
        raise ::ActiveRecord::Rollback if errors.any?
      end

      errors.empty?
    end
  end
end
