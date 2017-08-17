# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class UsersController < ::Api::BaseController
      skip_authorization_check only: [:signup]
      before_action :authenticate_user!, except: [:signup]

      def current
        authorize! :read, User
        @user = current_user
      end

      def signup
        @user = User.new(user_params)

        return if @user.save

        render json: ValidationError.new("signup", @user.errors), status: :bad_request
      end

      private def user_params
        @user_params ||= params.permit(:username, :email, :password, :password_confirmation)
      end
    end
  end
end
