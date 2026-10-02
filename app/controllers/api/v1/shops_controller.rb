# frozen_string_literal: true

module Api
  module V1
    class ShopsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[show]

      def show
        @shop = Shop.includes(location: [:system, :build, :last_build]).find_by!(slug: params[:slug].to_s.downcase)
        @items = ::Shops::Listing.new(@shop).call
        @ancestors = [*@shop.location.ancestors.reverse, @shop.location].reject { |place| place.kind == "star" }
      end
    end
  end
end
