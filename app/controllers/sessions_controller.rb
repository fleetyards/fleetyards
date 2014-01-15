class SessionsController < Devise::SessionsController
  before_action :set_active_nav

  private def set_active_nav
    @active_nav = 'sessions'
  end
end
