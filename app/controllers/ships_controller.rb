class ShipsController < ApplicationController
  before_action :set_active_nav
  before_filter :authenticate_user!, only: [:reload]

  def index
    authorize! :index, :ships
    @ships = find_ships
    @ships = @ships
      .order(sort_column + " " + sort_direction)
      .page(params.fetch(:page){nil})
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
    authorize! :show, :ships
    if ship.nil?
      redirect_to ships_path, alert: I18n.t(:"messages.record_not_found")
    end
  end

  def reload
    authorize! :reload, :ships
    respond_to do |format|
      format.js {
        Resque.enqueue ShipsWorker
        render json: true
      }
      format.html {
        redirect_to root_path
      }
    end
  end

  private def set_active_nav
    @active_nav = 'ships'
  end

  private def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
  helper_method :sort_direction

  private def sort_column
    @sort_column ||= begin
      column = (Ship.column_names + %w[ship_roles.name manufacturers.name]).include?(params[:sort]) ? params[:sort] : "ships.name"
    end
  end
  helper_method :sort_column

  private def ship
    @ship ||= Ship.where(slug: params.fetch(:slug, nil)).first
  end
  helper_method :ship

  private def find_ships
    ships = Ship.enabled.includes(:ship_role, :manufacturer)
    ship_role = params.fetch(:ship_role, nil)
    manufacturer = params.fetch(:manufacturer, nil)
    if ship_role.present?
      ships = ships.where("ship_roles.slug IN (?)", ship_role.split(', ')).references(:ship_role)
      params.delete(:page)
    end
    if manufacturer.present?
      ships = ships.where("manufacturers.slug IN (?)", manufacturer.split(', ')).references(:manufacturer)
      params.delete(:page)
    end
    if search = params.fetch(:search, nil)
      search_conditions = []
      search_conditions << "lower(ships.name) like :search"
      search_conditions << "lower(ships.description) like :search"
      ships = ships.where([
        search_conditions.join(' OR '),
        { search: "%#{search.downcase}%" }
      ])
    else
      unless params.fetch(:variants, nil)
        ships = ships.base
      end
    end
    ships
  end
end
