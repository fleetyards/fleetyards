# frozen_string_literal: true

module Short
  class BaseController < ApplicationController
    def hangar
      redirect_to frontend_public_hangar_url(username: params[:username]), allow_other_host: true
    end

    def fleet_invite
      redirect_to frontend_fleet_invite_url(token: params[:token]), allow_other_host: true
    end

    def trade_routes
      redirect_to frontend_tools_trade_routes_url(params: request.query_parameters), allow_other_host: true
    end

    def model_compare
      redirect_to frontend_compare_ships_url(params: request.query_parameters), allow_other_host: true
    end
  end
end
