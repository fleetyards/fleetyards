# encoding: utf-8
# frozen_string_literal: true
module Api
  module V1
    class ShipsController < ::Api::BaseController
      around_action :authenticate_user_from_token!, only: []

      def index
        authorize! :index, :api_ships
        @ships = Ship.all
                     .order("ships.name asc")
      end

      def show
        authorize! :show, :api_ships
        @ship = Ship.find(params[:id])
      end
    end
  end
end
