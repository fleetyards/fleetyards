class HangarsController < ApplicationController
  before_filter :authenticate_user!, only: [:show]

  def show
    @active_nav = 'hangar'
    authorize! :show, :hangar
  end

  def public
    @active_nav = 'hangar-public'
    authorize! :public, :hangar
    unless user.present?
      redirect_to root_path, alert: I18n.t("messages.user_not_found")
      return
    end
  end

  private def user
    @user ||= User.find_by(username: params[:username])
    @user ||= current_user
  end
  helper_method :user

  private def user_ships
    @user_ships ||= user.user_ships
      .page(params.fetch(:page, nil))
      .per(12)
  end
  helper_method :user_ships

  private def ship_roles
    @ship_roles ||= user_ships.group_by do |user_ship|
      user_ship.ship.ship_role.name
    end.map do |role, ships|
      "#{ships.size}x #{role}"
    end
  end
  helper_method :ship_roles
end
