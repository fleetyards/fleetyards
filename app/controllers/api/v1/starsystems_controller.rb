# frozen_string_literal: true

module Api
  module V1
    class StarsystemsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:starsystems) }, only: [:index]

      def index
        authorize! :index, :api_starsystems

        query_params['sorts'] = sort_by_name

        @q = Starsystem.visible.ransack(query_params)

        @starsystems = @q.result
                         .page(params[:page])
                         .per(per_page(Starsystem))
      end

      def show
        authorize! :show, :api_starsystems
        @starsystem = Starsystem.visible.find_by!(slug: params[:slug])
      end
    end
  end
end
