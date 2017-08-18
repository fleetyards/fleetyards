# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class HangarsController < ::Api::BaseController
      skip_authorization_check only: [:public]
      before_action :authenticate_user!, except: [:public]
      after_action { pagination_header(:user_ships) }

      def show
        authorize! :show, :api_hangar
        @user_ships = current_user.user_ships
                                  .unscoped
                                  .order(purchased: :desc, name: :asc, created_at: :desc)
                                  .page(params.fetch(:page, nil))
                                  .per(params.fetch(:perPage, nil))
      end

      def public
        user = User.find_by!("lower(username) = ?", params.fetch(:username, '').downcase)
        @user_ships = user.user_ships
                          .unscoped
                          .purchased
                          .order(name: :asc, created_at: :desc)
                          .page(params.fetch(:page, nil))
                          .per(params.fetch(:perPage, nil))
      end
    end
  end
end
