# frozen_string_literal: true

module Api
  module V1
    # Everything the catalogues carry, by name: the site search.
    class SearchController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      def index
        @groups = ::Catalogue::Search.new.call(params[:q])
      end
    end
  end
end
