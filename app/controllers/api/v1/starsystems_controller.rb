# frozen_string_literal: true

module Api
  module V1
    class StarsystemsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_starsystems

        query_params['sorts'] = sort_by_name

        @q = Starsystem.ransack(query_params)

        @starsystems = @q.result
      end

      def show
        authorize! :show, :api_starsystems
        @starsystem = Starsystem.find_by!(slug: params[:slug])
      end
    end
  end
end
