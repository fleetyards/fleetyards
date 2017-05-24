# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ShipsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action only: [:index] { pagination_header(:ships) }

      def index
        authorize! :index, :api_ships
        @ships = Ship.order("ships.name asc")
                     .page(params[:page])
                     .per(params[:per_page])
      end

      def show
        authorize! :show, :api_ships
        @ship = Ship.find_by(slug: params[:slug])
      end
    end
  end
end
