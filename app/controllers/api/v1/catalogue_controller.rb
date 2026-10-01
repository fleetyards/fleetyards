# frozen_string_literal: true

module Api
  module V1
    # The items a markdown text names inline, `[*Name*]` or `[*type:Name*]`.
    class CatalogueController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[lookup search]

      def lookup
        @matches = ::Catalogue::TokenResolver.new.resolve(params[:names])

        render :matches
      end

      def search
        @matches = ::Catalogue::TokenResolver.new.search(params[:q])

        render :matches
      end
    end
  end
end
