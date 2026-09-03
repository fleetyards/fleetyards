# frozen_string_literal: true

module Admin
  # The feed itself is open to any admin; which item types it carries is decided
  # per privilege in the controller, so an admin who may edit nothing sees an
  # empty list rather than a refusal.
  class VersionFeedPolicy < ApplicationPolicy
    alias_rule :index?, :recent?, to: :show?

    def show?
      user.present?
    end
  end
end
