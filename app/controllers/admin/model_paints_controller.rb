# frozen_string_literal: true

module Admin
  class ModelPaintsController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_model_paints
      @q = ModelPaint.ransack(params[:q])

      @q.sorts = ['model_name asc', 'name asc'] if @q.sorts.empty?

      @model_paints = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_model_paints
      @model_paint = ModelPaint.new
    end

    def create
      authorize! :create, :admin_model_paints
      @model_paint = ModelPaint.new(model_paint_params)
      if model_paint.save
        redirect_to admin_model_paints_path(params: index_back_params, anchor: model_paint.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.model_paint'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.model_paint'))
      end
    end

    def edit
      authorize! :update, model_paint
    end

    def update
      authorize! :update, model_paint
      if model_paint.update(model_paint_params)
        redirect_to admin_model_paints_path(params: index_back_params, anchor: model_paint.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.model_paint'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.model_paint'))
      end
    end

    def destroy
      authorize! :destroy, model_paint
      if model_paint.destroy
        redirect_to admin_model_paints_path(params: index_back_params, anchor: model_paint.id), notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.model_paint'))
      else
        redirect_to admin_model_paints_path(params: index_back_params, anchor: model_paint.id), error: I18n.t(:'messages..destroy.failure', resource: I18n.t(:'resources.model_paint'))
      end
    end

    def import
      authorize! :create, :admin_model_paints

      file_data = import_params[:paints_import]
      paints_data_raw = if file_data.respond_to?(:read)
                          file_data.read
                        elsif file_data.respond_to?(:path)
                          File.read(file_data.path)
                        end

      paints_data = JSON.parse(paints_data_raw)

      Loaders::PaintsImportJob.perform_later(paints_data)

      redirect_to admin_model_paints_path(params: index_back_params), notice: I18n.t(:'messages.import.success', resource: I18n.t(:'resources.model_paint'))
    end

    private def model_paint_params
      @model_paint_params ||= params.require(:model_paint).permit(
        :name, :hidden, :active, :store_image, :store_image_cache, :remove_store_image,
        :fleetchart_image, :fleetchart_image_cache, :remove_fleetchart_image,
        :top_view, :top_view_cache, :remove_top_view,
        :side_view, :side_view_cache, :remove_side_view,
        :angled_view, :angled_view_cache, :remove_angled_view,
        :pledge_price, :description, :model_id
      )
    end

    private def save_filters
      session[:model_paints_filters] = query_params(
        :model_id_eq, :name_cont
      ).to_h
      session[:model_paints_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:model_paints_filters],
        page: session[:model_paints_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def model_paint
      @model_paint ||= ModelPaint.where(id: params.fetch(:id, nil)).first
    end
    helper_method :model_paint

    private def set_active_nav
      @active_nav = 'admin-model_paints'
    end

    private def import_params
      @import_params ||= params.require(:model_paint).permit(:paints_import)
    end
  end
end
