# frozen_string_literal: true

module Admin
  class StarsystemsController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_starsystems

      query_params['sorts'] = sort_by_name

      @q = Starsystem.ransack(query_params)

      @starsystems = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_starsystems
      @starsystem = Starsystem.new
    end

    def create
      authorize! :create, :admin_starsystems
      @starsystem = Starsystem.new(starsystem_params)
      if starsystem.save
        redirect_to admin_starsystems_path(params: index_back_params, anchor: starsystem.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.starsystem"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.starsystem"))
      end
    end

    def edit
      authorize! :update, starsystem
    end

    def update
      authorize! :update, starsystem
      if starsystem.update(starsystem_params)
        redirect_to admin_starsystems_path(params: index_back_params, anchor: starsystem.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.starsystem"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.starsystem"))
      end
    end

    def destroy
      authorize! :destroy, starsystem
      if starsystem.destroy
        redirect_to admin_starsystems_path(params: index_back_params), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.starsystem"))
      else
        redirect_to admin_starsystems_path(params: index_back_params), error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.starsystem"))
      end
    end

    private def save_filters
      session[:starsystems_filters] = query_params(
        :name_or_slug_cont
      ).to_h
      session[:starsystems_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:starsystems_filters],
        page: session[:starsystems_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def starsystem_params
      @starsystem_params ||= params.require(:starsystem).permit(
        :name, :starsystem_id, :store_image, :store_image_cache, :remove_store_image,
        :hidden
      )
    end

    private def starsystem
      @starsystem ||= Starsystem.where(id: params.fetch(:id, nil)).first
    end
    helper_method :starsystem

    private def set_active_nav
      @active_nav = 'admin-starsystems'
    end
  end
end
