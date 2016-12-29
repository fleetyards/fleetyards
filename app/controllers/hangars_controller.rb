class HangarsController < ApplicationController
  before_action :set_active_nav

  def show
    authorize! :index, :hangar
    @user_ships = current_user.user_ships
      .order(created_at: :desc)
      .page(params.fetch(:page, nil))
      .per(12)
    respond_to do |format|
      format.js {
        render json: @user_ships
      }
      format.html {
        # render show
      }
    end
  end

  private def set_active_nav
    @active_nav = 'hangar'
  end

  private def user_ship_params
    @user_ship_params ||= params.permit(:name, :ship_id).merge(user_id: current_user.id)
  end

  private def user_ship
    @user_ship ||= UserShip.find(params[:id])
    @user_ship ||= UserShip.new(user_ship_params)
  end
end
