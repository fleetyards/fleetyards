# frozen_string_literal: true

class ShipsController < ApplicationController
  before_action :set_active_nav

  skip_authorization_check only: %i[index show gallery]
  before_action :authenticate_user!, only: [:reload]

  def index
    @ships = Ship.enabled
                 .filter(filter_params)
                 .order(name: :asc)
                 .page(params.fetch(:page, nil))
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
                  .page(params.fetch(:page, nil))
                  .per(24)
  end

  private def set_active_nav
    @active_nav = 'ships'
  end

  private def filter_params
    @filter_params ||= params.permit(
      :ship_role, :manufacturer, :production_status, :on_sale, :search
    )
  end
  helper_method :filter_params

  private def ship
    @ship ||= Ship.enabled.where(slug: params.fetch(:slug, nil)).first
  end
  helper_method :ship

  private def filters
    @filters ||= begin
      filters = []
      filters << Filter.new(resource: "ship", field: "ship_role", items: ShipRole.all, translateable: true)
      filters << Filter.new(resource: "ship", field: "manufacturer", items: Manufacturer.all)
      production_status_items = I18n.t("labels.ship.production_status").map do |status|
        {
          name: status[1],
          slug: status[0]
        }
      end
      filters << Filter.new(resource: "ship", field: "production_status", items: production_status_items)
      on_sale_items = %w[true false].map do |item|
        {
          name: I18n.t("filter.ship.on_sale.items.#{item}"),
          slug: item
        }
      end
      filters << Filter.new(resource: "ship", field: "on_sale", items: on_sale_items)
    end
  end
  helper_method :filters
end
