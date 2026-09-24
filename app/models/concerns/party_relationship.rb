# frozen_string_literal: true

# The handshake two parties agree to: one side asks, the other accepts,
# declines or ignores.
#
# Friendships and fleet alliances are two tables because each is consistently
# between one type -- user↔user and fleet↔fleet -- and neither needs the pairs
# of nullable foreign keys `inventory_transfers` and `inventory_transfer_rules`
# carry. What they do share is everything in this file, so the columns are named
# for the roles rather than for the types and the behaviour is stated once.
#
# Three answers, and the third is the one worth reading carefully. An ignore the
# requester can detect is a decline with worse manners, so `ignored` renders to
# the requester exactly as `pending` does -- see `state_for` -- and a further
# request from the same party is absorbed by the row rather than reaching
# anybody. That absorption is why this feature needs no block list: a permanent,
# silent, per-relationship refusal is what blocking would have been for here.
module PartyRelationship
  extend ActiveSupport::Concern

  # What one party may have waiting at once, so an inbox cannot be filled in a
  # burst. The same role `InventoryTransfer::OUTSTANDING_LIMIT` plays, and
  # larger because a request costs nothing to answer and holds nothing.
  OUTSTANDING_LIMIT = 50

  # The answers that end a request, and are the addressee's to give.
  ANSWERS = %i[accept decline ignore].freeze

  included do
    include AASM

    paginates_per 30

    validate :not_between_a_party_and_itself

    scope :involving, ->(party) { where(requester_id: party).or(where(addressee_id: party)) }
    scope :awaiting, ->(party) { pending.where(addressee_id: party) }
    scope :sent_by, ->(party) { where(requester_id: party) }
    scope :received_by, ->(party) { where(addressee_id: party) }

    # Rows in a state *as this party sees it*, which is not the same as rows in
    # that state. A request the other side ignored is still pending to whoever
    # sent it, so it has to be listed as pending too -- an ignore that is
    # invisible in `state_for` but visible by its absence from a list is not
    # invisible.
    #
    # Unless they withdrew it. Then it is gone as far as they are concerned, and
    # the row survives only to keep absorbing; listing it would be the same tell
    # from the other direction.
    scope :in_state_for, ->(state, party) {
      case state.to_s
      when "pending"
        where(aasm_state: "pending", withdrawn_at: nil)
          .or(where(aasm_state: "ignored", requester_id: party&.id, withdrawn_at: nil))
      when "ignored"
        where(aasm_state: "ignored", addressee_id: party&.id)
      else
        where(aasm_state: state)
      end
    }

    # `ignored` is deliberately absent from what the requester is shown, and
    # present for the addressee -- the whole point of an ignore is that these
    # two views of one row differ.
    aasm timestamps: true, whiny_transitions: false do
      state :pending, initial: true
      state :accepted
      state :declined
      state :ignored

      event :accept do
        transitions from: :pending, to: :accepted
      end

      event :decline do
        transitions from: :pending, to: :declined
      end

      event :ignore do
        transitions from: :pending, to: :ignored
      end
    end
  end

  class_methods do
    # The row between two parties in either direction, whatever state it is in.
    # There can only ever be one: the unordered unique index says so.
    def between(one, other)
      return if one.blank? || other.blank?

      where(requester_id: one, addressee_id: other)
        .or(where(requester_id: other, addressee_id: one))
        .first
    end

    def accepted_between?(one, other)
      return false if one.blank? || other.blank?

      between(one, other)&.accepted? || false
    end

    # The other end of every accepted relationship this party holds, as a
    # relation rather than an array so it composes as a subquery -- which is
    # what the bulk visibility filters need.
    def partner_ids_for(party)
      return none if party.blank?

      accepted.involving(party).select(
        Arel.sql(sanitize_sql_array(["CASE WHEN requester_id = ? THEN addressee_id ELSE requester_id END", party.id]))
      )
    end

    def outstanding_for(party)
      awaiting(party).count
    end

    def at_capacity?(party)
      outstanding_for(party) >= OUTSTANDING_LIMIT
    end
  end

  # What this row looks like to one of the two parties. An ignored request is
  # still pending as far as the person who sent it is concerned, and has to stay
  # that way in every payload, or ignoring somebody is merely a slower decline.
  def state_for(party)
    return aasm_state unless ignored?
    return "pending" if requester_id == party&.id

    aasm_state
  end

  # An ignored request its sender has since withdrawn. Kept only so that asking
  # again still goes nowhere; it is not a request any more, to anybody.
  def withdrawn?
    withdrawn_at.present?
  end

  def other_party_for(party)
    return addressee if requester_id == party&.id

    requester if addressee_id == party&.id
  end

  def involves?(party)
    return false if party.blank?

    requester_id == party.id || addressee_id == party.id
  end

  # Only the side that was asked may answer. The side that asked may call it
  # back, and either side may end an accepted one.
  def answerable_by?(party)
    pending? && addressee_id == party&.id
  end

  # Asked of the state the requester can see, not the real one: an ignored row
  # reads as pending to them, so refusing to cancel it would be the tell that
  # `state_for` exists to prevent. What actually happens to the row is
  # `Relationships::Answerer`'s business.
  def cancellable_by?(party)
    return false unless requester_id == party&.id
    return false if withdrawn?

    pending? || ignored?
  end

  private def not_between_a_party_and_itself
    return if requester_id.blank? || addressee_id.blank?
    return if requester_id != addressee_id

    errors.add(:base, :not_to_self)
  end
end
