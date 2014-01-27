class WeaponsController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: []

  def index
    authorize! :index, :weapons
    @weapons = Weapon
      .order('weapons.name desc')
      .page(params.fetch(:page, nil))
      .per(20)
  end

  def show
    authorize! :show, weapon
  end

  private def weapon
    @weapon ||= Weapon.where(id: params.fetch(:id, nil)).first
  end
  helper_method :weapon

  private def set_active_nav
    @active_nav = 'weapons'
  end
end
