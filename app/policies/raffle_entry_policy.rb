# frozen_string_literal: true

class RaffleEntryPolicy < ApplicationPolicy
  # Production already refuses sign-in to an unconfirmed account; this holds
  # for OAuth tokens and environments that allow unconfirmed access.
  def create?
    user.present? && user.confirmed?
  end

  def destroy?
    user.present? && record.user_id == user.id && record.raffle.open?
  end
end
