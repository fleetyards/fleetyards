# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class HangarsController < ::Api::V1::BaseController
      skip_authorization_check only: [:public]
      before_action :authenticate_api_user!, except: [:public]
      after_action only: [:show] { pagination_header(:user_ships) }
      after_action only: [:public] { pagination_header(:user_ships) }

      def show
        authorize! :show, :api_hangar
        @q = current_user.user_ships
                         .ransack(query_params)
        @user_ships = @q.result
                        .order(purchased: :desc, name: :asc, created_at: :desc)
                        .page(params[:page])
                        .per(params[:per_page])
      end

      def public
        user = User.find_by!("lower(username) = ?", params.fetch(:username, '').downcase)
        @user_ships = user.user_ships
                          .purchased
                          .order(name: :asc, created_at: :desc)
                          .page(params[:page])
                          .per(params[:per_page])
      end
    end
  end
end
