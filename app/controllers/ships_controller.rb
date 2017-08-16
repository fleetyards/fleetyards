# frozen_string_literal: true

class ShipsController < ApplicationController
  before_action :set_active_nav

  skip_authorization_check only: %i[index show gallery]
  before_action :authenticate_user!, only: [:reload]

  def index
    @ships = Ship.enabled
                 .order(name: :asc)
                 .page(params[:page])
                 .per(params[:per_page])
    respond_to do |format|
      format.js { render json: @ships }
      format.html {}
    end
  end

  def show
    redirect_to ships_path, alert: I18n.t(:"messages.record_not_found") if ship.nil?
  end

  def gallery
    @images = ship.images
                  .enabled
                  .order("created_at asc ")
                  .page(params[:page])
                  .per(params[:per_page])
  end

  private def set_active_nav
    @active_nav = 'ships'
  end

  private def ship
    @ship ||= Ship.enabled.where(slug: params.fetch(:slug, nil)).first
  end
  helper_method :ship
end
