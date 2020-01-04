# frozen_string_literal: true

module Admin
  class ModelsController < BaseController
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

    def new
      authorize! :create, :admin_models
      @model = Model.new
    end

    def create
      authorize! :create, :admin_models
      @model = Model.new(model_params)
      if model.save
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.model"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.model"))
      end
    end

    def edit
      authorize! :update, model
      model.build_addition if model.addition.blank?
    end

    def update
      authorize! :update, model
      if model.update(model_params)
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.model"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.model"))
      end
    end

    def destroy
      authorize! :destroy, model
      if model.destroy
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.model"))
      else
        redirect_to admin_models_path(params: index_back_params, anchor: model.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.model"))
      end
    end

    def images
      authorize! :images, :admin_models
    end

    def reload
      authorize! :reload, :admin_models
      respond_to do |format|
        format.js do
          ModelsWorker.perform_async
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
          ModelWorker.perform_async(model.rsi_id)
          render json: true
        end
        format.html do
          redirect_to root_path
        end
      end
    end

    private def model_params
      @model_params ||= params.require(:model).permit(
        :name, :hidden, :active, :ground, :store_image, :store_image_cache, :remove_store_image,
        :fleetchart_image, :fleetchart_image_cache, :remove_fleetchart_image,
        :brochure, :brochure_cache, :remove_brochure, :store_url, :base_model_id,
        :beam, :length, :height, :mass, :cargo, :pledge_price, :on_sale, :manufacturer_id, :focus,
        :classification, :description, :production_status, :production_note, :size,
        :scm_speed, :afterburner_speed, :cruise_speed, :ground_speed, :afterburner_ground_speed,
        :pitch_max, :yaw_max, :roll_max, :max_crew, :min_crew, :price, :last_pledge_price,
        :rsi_id, :dock_size, :erkuls_slug, :starship42_slug,
        videos_attributes: %i[id url video_type _destroy],
        docks_attributes: %i[id dock_type name ship_size length beam height _destroy]
      )
    end

    private def save_filters
      session[:models_filters] = params[:q]
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
