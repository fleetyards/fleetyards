# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ShipsController < ::Api::BaseController
      before_action :authenticate_api_user!, only: []

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.ship', slug: params[:slug]))
      end

      def index
        authorize! :index, :api_ships
        @ships = Ship.enabled
                     .filter(filter_params)
                     .order("ships.name asc")
      end

      def filters
        authorize! :index, :api_ships
        @filters ||= begin
          filters = []
          filters << ShipRole.with_name.with_ship.order(name: :asc).all.map do |ship_role|
            Filter.new(
              category: 'shipRole',
              name: ship_role.name,
              value: ship_role.slug
            )
          end
          filters << Manufacturer.enabled.with_name.with_ship.order(name: :asc).all.map do |manufacturer|
            Filter.new(
              category: 'manufacturer',
              name: manufacturer.name,
              value: manufacturer.slug
            )
          end
          filters << I18n.t("labels.ship.production_status").map do |status|
            Filter.new(
              category: 'productionStatus',
              name: status[1],
              value: status[0]
            )
          end
          filters << %w[true false].map do |item|
            Filter.new(
              category: 'onSale',
              name: I18n.t("filter.ship.on_sale.items.#{item}"),
              value: item
            )
          end
          filters.flatten
                 .sort_by { |filter| [filter.category, filter.name] }
        end
      end

      def categories
        authorize! :show, :api_ships
        @categories = ComponentCategory.all
      end

      def latest
        authorize! :index, :api_ships
        @ships = Ship.enabled
                     .order(updated_at: :asc)
                     .limit(10)
      end

      def updated
        authorize! :index, :api_ships
        if updated_range.present?
          scope = Ship.enabled
          scope = scope.where(updated_at: updated_range)
          @ships = scope.order(updated_at: :asc)
        else
          render json: [], status: :not_modified
        end
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
      end

      private def filter_params
        @filter_params ||= params.permit(
          :search, filter: []
        )
      end

      private def updated_range
        return if updated_params[:from].blank?
        to = updated_params[:to] || Time.zone.now
        [updated_params[:from]...to]
      end

      private def updated_params
        @updated_params ||= params.permit(
          :from, :to
        )
      end
    end
  end
end
