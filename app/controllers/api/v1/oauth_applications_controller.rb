# frozen_string_literal: true

module Api
  module V1
    class OauthApplicationsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! },
        unless: :user_signed_in?
      before_action :check_feature_flag
      before_action :set_application, only: %i[show update destroy regenerate_secret]

      def implicit_authorization_target
        Oauth::Application
      end

      def index
        authorize! Oauth::Application

        @applications = authorized_scope(Oauth::Application.all)
          .order(created_at: :desc)
      end

      def show
      end

      def create
        @application = Oauth::Application.new(application_params)
        @application.owner = current_resource_owner

        authorize! @application

        if @application.save
          render :create, status: :created
        else
          render json: ValidationError.new("oauth_application.create", errors: @application.errors), status: :bad_request
        end
      end

      def update
        if @application.update(application_params)
          render :show
        else
          render json: ValidationError.new("oauth_application.update", errors: @application.errors), status: :bad_request
        end
      end

      def destroy
        return if @application.destroy

        render json: ValidationError.new("oauth_application.destroy", errors: @application.errors), status: :bad_request
      end

      def regenerate_secret
        @application.renew_secret
        if @application.save
          render :regenerate_secret
        else
          render json: ValidationError.new("oauth_application.regenerate_secret", errors: @application.errors), status: :bad_request
        end
      end

      private def set_application
        @application = authorized_scope(Oauth::Application.all).find(params[:id])

        authorize! @application
      end

      private def application_params
        @application_params ||= params.transform_keys(&:underscore)
          .permit(:name, :redirect_uri, :confidential, scopes: [])
      end

      private def check_feature_flag
        return if feature_enabled?("oauth-applications")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
