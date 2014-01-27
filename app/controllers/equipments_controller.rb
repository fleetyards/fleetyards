class EquipmentsController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: []

  def index
    authorize! :index, :equipment
    @equipment = Equipment
      .order('equipment.name desc')
      .page(params.fetch(:page, nil))
      .per(20)
  end

  def show
    authorize! :show, equipment
  end

  private def equipment
    @equipment ||= Equipment.where(id: params.fetch(:id, nil)).first
  end
  helper_method :equipment

  private def set_active_nav
    @active_nav = 'equipment'
  end
end
