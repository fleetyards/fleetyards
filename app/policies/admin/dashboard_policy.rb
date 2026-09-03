# frozen_string_literal: true

module Admin
  # Not a BasePolicy subclass: the dashboard is not a gated resource but the
  # landing page every admin sees. What it may *contain* is gated, one privilege
  # per figure, in the controller.
  class DashboardPolicy < ApplicationPolicy
    alias_rule :index?, to: :show?

    def show?
      user.present?
    end
  end
end
