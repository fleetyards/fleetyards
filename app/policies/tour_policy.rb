# frozen_string_literal: true

# A tour has no fleet and no roles: the organiser created it, everyone else is
# on it because they joined. That is the whole authorization model.
class TourPolicy < ApplicationPolicy
  def index? = user.present?

  def show?
    organiser? || participant?
  end

  def create? = user.present?

  def update? = organiser?

  alias_rule :destroy?, :settle?, :reopen?, :cancel?, :rotate_invite?, to: :update?

  # Anyone with the link may join; the token is the credential.
  def join? = user.present?

  alias_rule :find_by_invite?, to: :join?

  relation_scope do |relation|
    next relation.none if user.blank?

    relation
      .left_joins(payout_ledger: :payout_participants)
      .where(
        "tours.created_by_id = :user_id OR payout_participants.user_id = :user_id",
        user_id: user.id
      )
      .distinct
  end

  params_filter do |params|
    params.permit(:title, :description, :starts_at)
  end

  private def organiser?
    user.present? && record.respond_to?(:created_by_id) && record.created_by_id == user.id
  end

  private def participant?
    return false if user.blank? || !record.respond_to?(:payout_ledger)

    record.payout_ledger&.payout_participants&.exists?(user_id: user.id) || false
  end
end
