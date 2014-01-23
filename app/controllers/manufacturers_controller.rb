class ManufacturersController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: []

  def index
    authorize! :index, :manufacturer
  end

  private def set_active_nav
    @active_nav = 'manufacturers'
  end
end
