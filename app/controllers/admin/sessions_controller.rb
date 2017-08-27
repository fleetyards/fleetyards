# frozen_string_literal: true

module Admin
  class SessionsController < Devise::SessionsController
    layout 'admin/application'
    before_action :set_active_nav

    private def set_active_nav
      @active_nav = 'sessions'
    end
  end
end
