# frozen_string_literal: true

module Relationships
  # Asking somebody to be a friend, or asking a fleet to be an ally.
  #
  # One service for both, because the columns are the same -- the only thing
  # that differs is which table the two ends point at, which the relation class
  # already says.
  #
  # Most of this is the four ways a request can meet a row that already exists,
  # and three of them are not "create":
  #
  #   nothing yet   a new pending row
  #   pending, addressed to the sender   **accept it** -- the two parties agreed,
  #                                      and the order they clicked in is not
  #                                      something the system should have an
  #                                      opinion about
  #   ignored       absorbed: answer as though it were sent, move nothing, tell
  #                 nobody. Anything else makes an ignore detectable, which is
  #                 the one thing it must never be
  #   declined      reopened as a fresh request. Declining is explicit and does
  #                 not claim to be permanent
  #
  # An ignored row is checked *before* the cap, and answers success regardless
  # of it. A cap refusal is about the addressee's inbox, and an ignored request
  # never reaches one -- consulting it here would make a full inbox the one
  # signal that told a sender they had been ignored.
  class Requester
    include ActiveModel::Model

    # Only two, and deliberately. A caller has to tell a request that is now
    # waiting from one that completed a relationship on the spot; everything
    # else -- absorbed, resent, reopened -- answers as `created`, because the
    # differences between them are things the sender must not be able to read.
    OUTCOMES = %i[created accepted].freeze

    attr_reader :relationship, :outcome

    def initialize(relation_class, requester:, addressee:)
      @relation_class = relation_class
      @requester = requester
      @addressee = addressee
    end

    def call
      return false unless both_parties_present?
      return false if between_a_party_and_itself?

      @relationship = @relation_class.between(@requester, @addressee)

      return absorb if @relationship&.ignored?
      return already_related if @relationship&.accepted?
      return accept_theirs if crossing_request?
      return resend if @relationship&.pending?
      return reopen if @relationship&.declined?

      create
    end

    def success? = errors.empty?

    # The request the sender is answering without knowing it: a pending row this
    # party was asked by.
    private def crossing_request?
      @relationship&.pending? && @relationship.addressee_id == @requester.id
    end

    private def create
      return false if at_capacity?

      @relationship = @relation_class.new(requester: @requester, addressee: @addressee)

      unless @relationship.save
        errors.merge!(@relationship.errors)
        return false
      end

      @outcome = :created
      true
    rescue ::ActiveRecord::RecordNotUnique
      # Two requests for the same pair landed at once and the unordered unique
      # index turned one of them away. The row that won is the answer to both,
      # so re-read and let the branches above decide what this one means.
      @relationship = @relation_class.between(@requester, @addressee)
      return false if @relationship.blank?

      crossing_request? ? accept_theirs : resend
    end

    private def accept_theirs
      unless @relationship.accept!
        errors.add(:base, :already_resolved)
        return false
      end

      @outcome = :accepted
      true
    end

    private def reopen
      return false if at_capacity?

      # Back to the start rather than a new row: the unordered pair is unique,
      # and the timestamps of the refusal it replaces are no longer true of it.
      unless @relationship.update(aasm_state: "pending", declined_at: nil)
        errors.merge!(@relationship.errors)
        return false
      end

      @outcome = :created
      true
    end

    # Already sent, still waiting. Idempotent on purpose -- a second press of
    # the button is not an error, and must not read as one.
    private def resend
      @outcome = :created
      true
    end

    private def absorb
      @outcome = :created
      true
    end

    private def already_related
      errors.add(:base, :already_related)
      false
    end

    private def at_capacity?
      return false unless @relation_class.at_capacity?(@addressee)

      errors.add(:base, :at_capacity)
      true
    end

    private def both_parties_present?
      return true if @requester.present? && @addressee.present?

      errors.add(:base, :not_found)
      false
    end

    private def between_a_party_and_itself?
      return false unless @requester.id == @addressee.id

      errors.add(:base, :not_to_self)
      true
    end
  end
end
