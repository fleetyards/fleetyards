# frozen_string_literal: true

class RafflePolicy < ApplicationPolicy
  alias_rule :entrants?, to: :show?

  def current?
    true
  end

  def show?
    record.published?
  end
end
