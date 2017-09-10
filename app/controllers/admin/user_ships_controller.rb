# frozen_string_literal: true

module Admin
  class UserShipsController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_user_ships
      @q = UserShip.ransack(params[:q])
      @user_ships = @q.result
                      .page(params.fetch(:page) { nil })
                      .per(40)
    end

    private def save_filters
      session[:user_ships_filters] = params[:q]
      session[:user_ships_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:user_ships_filters],
        page: session[:user_ships_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def set_active_nav
      @active_nav = 'admin-user-ships'
    end
  end
end
