# frozen_string_literal: true

module Api
  module V2
    class AuthTokensController < ::Api::V2::BaseController
      def index
        authorize! :index, :api_auth_tokens
        @auth_tokens = AuthToken.where(user_id: current_user.id)
          .order([{ created_at: :asc }])
          .page(params[:page])
          .per(per_page(AuthToken))
      end

      def create
        @auth_token = AuthToken.new(auth_token_params)
        authorize! :create, auth_token

        @token = auth_token.generate_token

        if auth_token.save
          render status: :created
        else
          render json: ValidationError.new("auth_token.create", errors: @auth_token.errors), status: :bad_request
        end
      end

      def destroy
        authorize! :destroy, auth_token

        return if auth_token.destroy

        render json: ValidationError.new("auth_token.destroy", errors: @auth_token.errors), status: :bad_request
      end

      private def auth_token
        @auth_token ||= AuthToken.find_by!(user_id: current_user.id, id: params[:id])
      end
      helper_method :auth_token

      private def auth_token_params
        @auth_token_params ||= params.permit(:description, :expired_at).merge(user_id: current_user.id)
      end
    end
  end
end
