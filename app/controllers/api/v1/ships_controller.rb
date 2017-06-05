# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ShipsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action only: [:index] { pagination_header(:ships) }
      after_action only: [:gallery] { pagination_header(:images) }

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.ship', slug: params[:slug]))
      end

      def index
        authorize! :index, :api_ships
        @ships = Ship.enabled
                     .order("ships.name asc")
                     .page(params[:page])
                     .per(params[:per_page])
      end

      def latest
        authorize! :index, :api_ships
        @ships = Ship.enabled
                     .order("RANDOM()")
                     .limit(10)
      end

      def show
        authorize! :show, :api_ships
        @ship = Ship.enabled
                    .find_by!(slug: params[:slug])
      end

      def gallery
        authorize! :index, :api_ships
        ship = Ship.find_by!(slug: params[:slug])
        @images = ship.images
                      .enabled
                      .order(created_at: :asc)
                      .page(params.fetch(:page, nil))
                      .per(params[:per_page])
      end
    end
  end
end
