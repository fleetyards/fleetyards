# frozen_string_literal: true

module Api
  module V1
    class ShopsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[show items]

      after_action -> { pagination_header(:items) }, only: [:items]

      def show
        @shop = Shop.includes(location: [:system, :build, :last_build]).find_by!(slug: params[:slug].to_s.downcase)
        @items = ::Shops::Listing.new(@shop).call
        @ancestors = [*@shop.location.ancestors.reverse, @shop.location].reject { |place| place.kind == "star" }
      end

      def items
        shop = Shop.find_by!(slug: params[:slug].to_s.downcase)
        query = params.permit(q: [:s, :name_cont, category_in: []]).fetch(:q, {})

        rows = ::Shops::Items.new(shop, name_cont: query[:name_cont], category_in: query[:category_in], sort: query[:s]).call

        @items = Kaminari.paginate_array(rows).page(page_params).per(per_page(Shop))
      end
    end
  end
end
