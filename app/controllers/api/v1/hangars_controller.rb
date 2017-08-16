# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class HangarsController < ::Api::BaseController
      before_action :authenticate_user!, only: [:show]
      after_action { pagination_header(:user_ships) }

      def show
        authorize! :show, :api_hangar
        @user_ships = current_user.user_ships
                                  .unscoped
                                  .order(purchased: :desc, created_at: :desc)
                                  .page(params.fetch(:page, nil))
                                  .per(params.fetch(:perPage, nil))
      end

      def public
        authorize! :public, :api_hangar
        user = User.find_by!("lower(username) = ?", params.fetch(:username, '').downcase)
        @user_ships = user.user_ships
                          .purchased
                          .order(created_at: :desc)
                          .page(params.fetch(:page, nil))
                          .per(params.fetch(:perPage, nil))
      end
    end
  end
end
