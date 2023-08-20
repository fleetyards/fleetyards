# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ShopCommoditiesController < ::Api::PublicBaseController
        def sub_categories
          allowed_categories = nil

          if params[:shopSlug].present? && params[:stationSlug].present?
            station = Station.find_by(slug: params[:stationSlug])
            shop = Shop.find_by(slug: params[:shopSlug], station_id: station.id)
            allowed_categories = shop.shop_commodities.includes(:commodity_item).map(&:sub_category)
          end

          @filters = [
            Model.classification_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) },
            Equipment.type_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) },
            Component.class_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) }
          ].flatten.sort_by { |category| [category.category, category.label] }
        end

        def commodity_item_types
          @commodity_item_types = ShopCommodity.commodity_item_types.map do |item_type|
            {
              name: I18n.t("activerecord.attributes.shop_commodity.commodity_item_types.#{item_type}"),
              value: item_type
            }
          end.sort_by { |item| item[:name] }
        end
      end
    end
  end
end
