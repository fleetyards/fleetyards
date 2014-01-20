class EquipmentsController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: []

  def index
    authorize! :index, :equipment
  end

  private def set_active_nav
    @active_nav = 'equipment'
  end
end
