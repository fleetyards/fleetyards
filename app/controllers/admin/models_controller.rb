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
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.model"))
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

    def gallery
      authorize! :gallery, :admin_models
      respond_to do |format|
        format.js do
          images = model.images.order('created_at desc').all
          jq_images = images.collect(&:to_jq_upload)
          render json: { files: jq_images }.to_json
        end
        format.html do
          # render upload form
        end
      end
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
          ModelWorker.perform_async(model.name)
          render json: true
        end
        format.html do
          redirect_to root_path
        end
      end
    end

    private def model_params
      @model_params ||= params.require(:model).permit(
        :name, :store_image, :store_image_cache, :remove_store_image,
        :fleetchart_image, :fleetchart_image_cache, :remove_fleetchart_image,
        addition_attributes: %i[
          id beam length height mass cargo net_cargo price crew _destroy
        ],
        videos_attributes: %i[
          id url video_type _destroy
        ]
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
