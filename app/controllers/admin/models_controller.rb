# frozen_string_literal: true

module Admin
  class ModelsController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_models
      @q = Model.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @models = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def name_diff
      authorize! :index, :admin_models

      @active_nav = 'admin-models-name-diff'

      @q = Model.where('name != rsi_name AND rsi_id IS NOT NULL').ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @models = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def price_diff
      authorize! :index, :admin_models

      @active_nav = 'admin-models-price-diff'

      @q = Model.where('pledge_price != last_pledge_price AND rsi_id IS NOT NULL').ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @models = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_models
      @model = Model.new
    end

    def edit
      authorize! :update, model
      model.build_addition if model.addition.blank?
    end

    def create
      authorize! :create, :admin_models
      @model = Model.new(model_params)
      if model.save
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.model'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.model'))
      end
    end

    def update
      authorize! :update, model
      if model.update(model_params)
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.model'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.model'))
      end
    end

    def destroy
      authorize! :destroy, model
      if model.destroy
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.model'))
      else
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), error: I18n.t(:'messages..destroy.failure', resource: I18n.t(:'resources.model'))
      end
    end

    def use_rsi_image
      authorize! :update, model

      if model.update(remote_store_image_url: model.rsi_store_image_url)
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.model'))
      else
        Rails.logger.info model.errors.to_a.to_yaml
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.model'))
      end
    end

    def images
      authorize! :images, :admin_models

      redirect_to admin_models_path(params: index_back_params, anchor: model&.id) if model.blank?

      @app_enabled = true
    end

    def reload
      authorize! :reload, :admin_models
      respond_to do |format|
        format.js do
          Loaders::ModelsJob.perform_async
          render json: true
        end
        format.html do
          redirect_to root_path
        end
      end
    end

    def reload_data
      authorize! :reload, :admin_models
      respond_to do |format|
        format.js do
          Loaders::ScDataShipsJob.perform_async(version: load_version_from_s3)
          render json: true
        end
        format.html do
          redirect_to root_path
        end
      end
    end

    def reload_one
      authorize! :reload, :admin_models
      respond_to do |format|
        format.js do
          Loaders::ModelJob.perform_async(model.rsi_id)
          Loaders::ScDataShipJob.perform_async(model.id) if model.sc_identifier.present?
          render json: true
        end
        format.html do
          redirect_to root_path
        end
      end
    end

    private def model_params
      @model_params ||= params.require(:model).permit(
        :name, :hidden, :notified, :active, :ground, :store_image, :store_image_cache,
        :remove_store_image, :rsi_store_image, :remove_rsi_store_image, :quantum_fuel_tank_size,
        :hydrogen_fuel_tank_size, :fleetchart_image, :fleetchart_image_cache,
        :remove_fleetchart_image, :top_view, :top_view_cache, :remove_top_view, :side_view,
        :side_view_cache, :remove_side_view, :brochure, :brochure_cache, :remove_brochure,
        :store_url, :base_model_id, :holo_colored, :holo, :holo_cache, :remove_holo, :beam,
        :length, :height, :mass, :cargo, :pledge_price, :on_sale, :manufacturer_id, :focus,
        :classification, :description, :production_status, :production_note, :size, :scm_speed,
        :afterburner_speed, :cruise_speed, :ground_speed, :afterburner_ground_speed, :pitch_max,
        :yaw_max, :roll_max, :max_crew, :min_crew, :price, :last_pledge_price, :rsi_id, :dock_size,
        :sc_identifier, :erkul_identifier, :sales_page_url, :angled_view, :angled_view_cache,
        :remove_angled_view, :fleetchart_offset_length,
        videos_attributes: %i[id url video_type _destroy],
        docks_attributes: %i[id dock_type name ship_size length beam height _destroy]
      )
    end

    private def save_filters
      session[:models_filters] = query_params(
        :manufacturer_id_eq, :name_or_slug_cont
      ).to_h
      session[:models_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:models_filters],
        page: session[:models_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def model
      @model ||= Model.where(id: params.fetch(:id, nil)).first
    end
    helper_method :model

    private def set_active_nav
      @active_nav = 'admin-models'
    end
  end
end
