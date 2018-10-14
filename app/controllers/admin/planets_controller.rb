# frozen_string_literal: true

module Admin
  class PlanetsController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_planets
      @q = Planet.ransack(params[:q])
      @planets = @q.result
                   .page(params.fetch(:page) { nil })
                   .per(40)
    end

    def new
      authorize! :create, :admin_planets
      @planet = Planet.new
    end

    def create
      authorize! :create, :admin_planets
      @planet = Planet.new(planet_params)
      if planet.save
        redirect_to admin_planets_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.planet"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.planet"))
      end
    end

    def edit
      authorize! :update, planet
    end

    def update
      authorize! :update, planet
      if planet.update(planet_params)
        redirect_to edit_admin_planet_path(planet), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.planet"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.planet"))
      end
    end

    def destroy
      authorize! :destroy, planet
      if planet.destroy
        redirect_to admin_planets_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.planet"))
      else
        redirect_to admin_planets_path, error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.planet"))
      end
    end

    private def save_filters
      session[:planets_filters] = params[:q]
      session[:planets_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:planets_filters],
        page: session[:planets_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def planet_params
      @planet_params ||= params.require(:planet).permit(
        :name, :starsystem_id, :store_image, :store_image_cache, :remove_store_image,
        :map, :map_cache, :remove_map
      )
    end

    private def planet
      @planet ||= Planet.where(id: params.fetch(:id, nil)).first
    end
    helper_method :planet

    private def set_active_nav
      @active_nav = 'admin-planets'
    end
  end
end
