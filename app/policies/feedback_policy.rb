# frozen_string_literal: true

class FeedbackPolicy < ApplicationPolicy
  def create?
    user.present?
  end
end
