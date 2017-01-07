class ShipsController < ApplicationController
  before_action :set_active_nav

  skip_authorization_check only: [:index, :show, :gallery]
  before_action :authenticate_user!, only: [:reload]

  caches_action :index, layout: false, cache_path: Proc.new { |c| c.params }

  def index
    @available_production_status = I18n.t("labels.ship.production_status").map do |status|
      {
        name: status[1],
        slug: status[0]
      }
    end
    @ships = find_ships
    @ships = @ships
      .order(name: :asc)
      .page(params.fetch(:page, nil))
      .per(8)
    respond_to do |format|
      format.js {
        render json: @ships
      }
      format.html {
        # render index
      }
    end
  end

  def show
    if ship.nil?
      redirect_to ships_path, alert: I18n.t(:"messages.record_not_found")
      return
    end
  end

  def gallery
    authorize! :gallery, ship
    @images = ship.images.enabled
      .order("created_at asc ")
      .page(params.fetch(:page){nil})
      .per(24)
  end

  private def set_active_nav
    @active_nav = 'ships'
  end

  private def ship
    @ship ||= Ship.where(slug: params.fetch(:slug, nil)).first
  end
  helper_method :ship

  private def find_ships
    ships = Ship.enabled.includes(:ship_role, :manufacturer)
    ship_role = params.fetch(:ship_role, nil)
    manufacturer = params.fetch(:manufacturer, nil)
    production_status = params.fetch(:production_status, nil)
    search = params.fetch(:search, nil)

    if ship_role.present?
      ships = ships.where("ship_roles.slug = ?", ship_role).references(:ship_role)
    end

    if manufacturer.present?
      ships = ships.where("manufacturers.slug = ?", manufacturer).references(:manufacturer)
    end

    if production_status.present?
      ships = ships.where(production_status: production_status)
    end

    if search.present?
      search_conditions = []
      search_conditions << "lower(ships.name) like :search"
      search_conditions << "lower(ships.description) like :search"
      ships = ships.where([
        search_conditions.join(' OR '),
        { search: "%#{search.downcase}%" }
      ])
    end

    ships
  end
end
