# frozen_string_literal: true

# Transfers are authorised against the inventories and parties they name rather
# than against a holder, because the two ends of one may belong to different
# people. The real decisions live in `Inventories::TransferAuthorizer`, which
# the services and this policy both call, so the rule has one definition.
class InventoryTransferPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  # Reading one: either end, or the party it is addressed to.
  def show?
    return false if user.blank?

    authorizer.may_withdraw_from?(record.source) ||
      authorizer.may_deposit_into?(record.destination) ||
      authorizer.may_answer_for?(record.recipient_party)
  end

  def create?
    user.present?
  end

  # Answering it. The destination itself is checked by the resolver, against the
  # person accepting rather than against the party recorded when it was sent.
  def accept?
    user.present? && authorizer.may_answer_for?(record.recipient_party)
  end

  alias_rule :decline?, :report?, to: :accept?

  # Calling it back is the sending side's move, so it is authorised against the
  # source rather than against the recipient.
  def cancel?
    user.present? && authorizer.may_withdraw_from?(record.source)
  end

  private def authorizer
    @authorizer ||= ::Inventories::TransferAuthorizer.new(user)
  end
end
