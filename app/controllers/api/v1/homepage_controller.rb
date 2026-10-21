# frozen_string_literal: true

module Api
  module V1
    # What the team curates on the landing page.
    class HomepageController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[show]

      def show
        @search_suggestions = ::Homepage::SearchSuggestions.new.call
        @featured_ship = HomepageSetting.current.featured_ship
      end
    end
  end
end
