class ManufacturersController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: []

  def index
    authorize! :index, :manufacturers
    @manufacturers = Manufacturer.known
      .order('manufacturers.name desc')
      .page(params.fetch(:page, nil))
      .per(20)
  end

  private def set_active_nav
    @active_nav = 'manufacturers'
  end
end
