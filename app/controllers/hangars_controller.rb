# frozen_string_literal: true

class HangarsController < ApplicationController
  skip_authorization_check only: [:public]
  before_action :authenticate_user!, only: [:show]

  def show
    @user = current_user
    @active_nav = 'hangar'
    authorize! :show, :hangar
  end

  def public
    @active_nav = 'hangar-public'
    redirect_to root_path, alert: I18n.t("messages.user_not_found") if user.blank?
  end

  private def user
    @user ||= User.find_by("lower(username) = ?", (params[:username] || "").downcase)
  end
  helper_method :user

  private def purchased_user_ships
    @purchased_user_ships ||= user.user_ships
                              .purchased
                              .page(params.fetch(:page, nil))
                              .per(12)
  end
  helper_method :purchased_user_ships

  private def user_ships
    @user_ships ||= user.user_ships
                    .unscoped
                    .order(purchased: :desc, created_at: :desc)
                    .page(params.fetch(:page, nil))
                    .per(12)
  end
  helper_method :user_ships

  private def ship_roles
    @ship_roles ||= user_ships.group_by do |user_ship|
      user_ship.ship.ship_role_name
    end.map do |role, ships|
      "#{ships.size}x #{role}"
    end
  end
  helper_method :ship_roles
end
