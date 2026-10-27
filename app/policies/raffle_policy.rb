# frozen_string_literal: true

class RafflePolicy < ApplicationPolicy
  alias_rule :entrants?, to: :show?

  def index?
    true
  end

  def show?
    record.published?
  end

  # Only the current winner, and only through their own account: a winner
  # without one is handed the code by an admin after verifying them.
  def claim?
    winning_entry.present?
  end

  alias_rule :code?, to: :claim?

  relation_scope do |relation|
    relation.published
  end

  private def winning_entry
    return if user.blank?

    record.current_winner&.then { |entry| entry if entry.user_id == user.id }
  end
end
