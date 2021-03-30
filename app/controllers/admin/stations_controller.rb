# frozen_string_literal: true

module Admin
  class StationsController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_stations
      @q = Station.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @stations = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_stations
      @station = Station.new
    end

    def create
      authorize! :create, :admin_stations
      @station = Station.new(station_params)
      if station.save
        redirect_to edit_admin_station_path(station.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.station"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.station"))
      end
    end

    def edit
      authorize! :update, station
    end

    def update
      authorize! :update, station
      if station.update(station_params)
        redirect_to edit_admin_station_path(station.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.station"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.station"))
      end
    end

    def destroy
      authorize! :destroy, station
      if station.destroy
        redirect_to admin_stations_path(params: index_back_params, anchor: station.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.station"))
      else
        redirect_to admin_stations_path(params: index_back_params, anchor: station.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.station"))
      end
    end

    def images
      authorize! :images, :admin_stations
      @app_enabled = true
    end

    private def station_params
      @station_params ||= params.require(:station).permit(
        :name, :station_type, :hidden, :store_image, :store_image_cache, :remove_store_image,
        :celestial_object_id, :location, :map, :map_cache, :remove_map, :cargo_hub, :refinery,
        docks_attributes: %i[id dock_type name ship_size length beam height _destroy]
      )
    end

    private def save_filters
      session[:stations_filters] = query_params(
        :name_or_slug_cont, :station_type_eq, :celestial_object_id_eq
      ).to_h
      session[:stations_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:stations_filters],
        page: session[:stations_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def station
      @station ||= Station.where(id: params.fetch(:id, nil)).first
    end
    helper_method :station

    private def set_active_nav
      @active_nav = 'admin-stations'
    end
  end
end
