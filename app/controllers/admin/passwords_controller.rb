# frozen_string_literal: true

module Admin
  class PasswordsController < Devise::PasswordsController
    layout 'admin/application'
    before_action :set_active_nav

    private def set_active_nav
      @active_nav = 'users'
    end
  end
end
