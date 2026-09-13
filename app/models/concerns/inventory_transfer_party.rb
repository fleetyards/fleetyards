# frozen_string_literal: true

# What a user and a fleet have in common as the *recipient* of a transfer: a
# stance on who may send them one, a set of exceptions to it, and the sanction
# an admin can apply to them as a sender.
#
# Both sides of every pair are the same two classes, so this is the one place
# that knows a "party" is a User or a Fleet.
module InventoryTransferParty
  extend ActiveSupport::Concern

  # Who may send this party a transfer they have to answer.
  #
  # `everyone` is the default deliberately. The ask was to be able to *disable*
  # incoming transfers, which presumes they are on; defaulting to `known` would
  # make the feature's main use -- settling up with a hauler you just met --
  # fail silently for almost everybody. The cap, the rules and the report queue
  # are what contain the abuse instead.
  POLICIES = {everyone: 0, known: 1, nobody: 2}.freeze

  included do
    enum :inventory_transfer_policy, POLICIES, prefix: :transfers_from

    # The rules this party holds, and the rules other parties hold about it.
    # Both keyed off the class name, because the column pairs are named for the
    # two types rather than being polymorphic.
    has_many :inventory_transfer_rules, dependent: :destroy,
      foreign_key: :"#{model_name.singular}_id", inverse_of: model_name.singular.to_sym

    has_many :inventory_transfer_rules_about, class_name: "InventoryTransferRule",
      foreign_key: :"subject_#{model_name.singular}_id", dependent: :destroy,
      inverse_of: :"subject_#{model_name.singular}"
  end

  # Under a platform sanction: may not send transfers at all. Narrower than
  # Devise's `locked_at`, which takes the whole account.
  def transfers_blocked?
    transfers_blocked_at.present?
  end

  def block_transfers!(reason:, at: Time.current)
    update!(transfers_blocked_at: at, transfers_blocked_reason: reason)
  end

  def unblock_transfers!
    update!(transfers_blocked_at: nil, transfers_blocked_reason: nil)
  end

  # The standing exception this party holds about another, if any.
  def transfer_rule_about(party)
    ::InventoryTransferRule.between(holder: self, subject: party)
  end
end
