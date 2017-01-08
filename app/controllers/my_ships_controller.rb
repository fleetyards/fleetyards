class MyShipsController < ApplicationController
  before_action :set_active_nav

  def new
    @user_ship = UserShip.new(user_id: current_user.id, ship_id: ship.id)
    authorize! :create, user_ship
  end

  def edit
    authorize! :update, user_ship
  end

  def create
    authorize! :create, user_ship
    if user_ship.save
      redirect_to ship_path(ship.slug), notice: I18n.t("messages.create.success",
        resource: I18n.t("resources.my_ship")
      )
    else
      redirect_to ship_path(ship.slug), alert: I18n.t("messages.create.failure",
        resource: I18n.t("resources.my_ship")
      )
    end
  end

  def update
    authorize! :update, user_ship
    if user_ship.update(user_ship_params)
      redirect_to hangar_path, notice: I18n.t("messages.update.success",
        resource: I18n.t("resources.my_ship")
      )
    else
      redirect_to hangar_path, alert: I18n.t("messages.update.failure",
        resource: I18n.t("resources.my_ship")
      )
    end
  end

  def destroy
    authorize! :destroy, user_ship
    if user_ship.destroy
      redirect_to :back, notice: I18n.t("messages.destroy.success",
        resource: I18n.t("resources.my_ship")
      )
    else
      redirect_to :back, alert: I18n.t("messages.destroy.failure",
        resource: I18n.t("resources.my_ship")
      )
    end
  end

  private def set_active_nav
    @active_nav = 'hangar'
  end

  private def user_ship_params
    @user_ship_params ||= params.require(:user_ship).permit(:name, :ship_id).merge({
      user_id: current_user.id
    })
  end

  private def ship
    @ship ||= Ship.find_by(slug: params[:ship])
    @ship ||= Ship.find_by(id: user_ship.ship_id || user_ship_params[:ship_id])
  end
  helper_method :ship

  private def user_ship
    @user_ship ||= UserShip.find_by(id: params[:id])
    @user_ship ||= UserShip.new(user_ship_params)
  end
  helper_method :user_ship
end
