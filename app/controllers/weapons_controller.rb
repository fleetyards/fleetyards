class WeaponsController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: []

  def index
    authorize! :index, :weapons
  end

  private def set_active_nav
    @active_nav = 'weapons'
  end
end
