# frozen_string_literal: true

module Admin
  class CelestialObjectsController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_celestial_objects

      query_params['sorts'] = sort_by_name

      @q = CelestialObject.ransack(query_params)

      @celestial_objects = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_celestial_objects
      @celestial_object = CelestialObject.new
    end

    def create
      authorize! :create, :admin_celestial_objects
      @celestial_object = CelestialObject.new(celestial_object_params)
      if celestial_object.save
        redirect_to admin_celestial_objects_path(params: index_back_params, anchor: celestial_object.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.celestial_object'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.celestial_object'))
      end
    end

    def edit
      authorize! :update, celestial_object
    end

    def update
      authorize! :update, celestial_object
      if celestial_object.update(celestial_object_params)
        redirect_to admin_celestial_objects_path(params: index_back_params, anchor: celestial_object.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.celestial_object'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.celestial_object'))
      end
    end

    def destroy
      authorize! :destroy, celestial_object
      if celestial_object.destroy
        redirect_to admin_celestial_objects_path(params: index_back_params), notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.celestial_object'))
      else
        redirect_to admin_celestial_objects_path(params: index_back_params), error: I18n.t(:'messages.destroy.failure', resource: I18n.t(:'resources.celestial_object'))
      end
    end

    private def save_filters
      session[:celestial_objects_filters] = query_params(
        :name_or_slug_cont, :starsystem_id_eq
      ).to_h
      session[:celestial_objects_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:celestial_objects_filters],
        page: session[:celestial_objects_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def celestial_object_params
      @celestial_object_params ||= params.require(:celestial_object).permit(
        :name, :starsystem_id, :store_image, :store_image_cache, :remove_store_image,
        :hidden
      )
    end

    private def celestial_object
      @celestial_object ||= CelestialObject.where(id: params.fetch(:id, nil)).first
    end
    helper_method :celestial_object

    private def set_active_nav
      @active_nav = 'admin-celestial_objects'
    end
  end
end
