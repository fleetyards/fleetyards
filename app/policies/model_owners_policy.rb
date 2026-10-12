# frozen_string_literal: true

class ModelOwnersPolicy < ApplicationPolicy
  def index?
    user.present?
  end
end
