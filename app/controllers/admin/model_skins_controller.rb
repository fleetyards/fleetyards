# frozen_string_literal: true

module Admin
  class ModelSkinsController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_model_skins
      @q = ModelSkin.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @model_skins = @q.result
                       .page(params.fetch(:page) { nil })
                       .per(40)
    end

    def new
      authorize! :create, :admin_model_skins
      @model_skin = ModelSkin.new
    end

    def create
      authorize! :create, :admin_model_skins
      @model_skin = ModelSkin.new(model_skin_params)
      if model_skin.save
        redirect_to admin_model_skins_path(params: index_back_params, anchor: model_skin.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.model_skin"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.model_skin"))
      end
    end

    def edit
      authorize! :update, model_skin
    end

    def update
      authorize! :update, model_skin
      if model_skin.update(model_skin_params)
        redirect_to admin_model_skins_path(params: index_back_params, anchor: model_skin.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.model_skin"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.model_skin"))
      end
    end

    def destroy
      authorize! :destroy, model_skin
      if model_skin.destroy
        redirect_to admin_model_skins_path(params: index_back_params, anchor: model_skin.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.model_skin"))
      else
        redirect_to admin_model_skins_path(params: index_back_params, anchor: model_skin.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.model_skin"))
      end
    end

    private def model_skin_params
      @model_skin_params ||= params.require(:model_skin).permit(
        :name, :hidden, :active, :store_image, :store_image_cache, :remove_store_image,
        :pledge_price, :description, :model_id
      )
    end

    private def save_filters
      session[:model_skins_filters] = params[:q]
      session[:model_skins_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:model_skins_filters],
        page: session[:model_skins_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def model_skin
      @model_skin ||= ModelSkin.where(id: params.fetch(:id, nil)).first
    end
    helper_method :model_skin

    private def set_active_nav
      @active_nav = 'admin-model_skins'
    end
  end
end
