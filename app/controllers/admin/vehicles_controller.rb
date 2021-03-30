# frozen_string_literal: true

module Admin
  class VehiclesController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_vehicles
      @q = Vehicle.ransack(params[:q])
      @vehicles = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    private def save_filters
      session[:vehicles_filters] = query_params(
        :name_cont
      ).to_h
      session[:vehicles_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:vehicles_filters],
        page: session[:vehicles_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def set_active_nav
      @active_nav = 'admin-vehicles'
    end
  end
end
