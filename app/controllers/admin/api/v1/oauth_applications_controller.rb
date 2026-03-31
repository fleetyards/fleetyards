# frozen_string_literal: true

module Admin
  module Api
    module V1
      class OauthApplicationsController < ::Admin::Api::BaseController
        before_action :set_application, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::OauthApplicationPolicy

          @oauth_applications = Oauth::Application.all
            .includes(:owner)
            .ransack(oauth_application_query_params)
            .result
            .order(created_at: :desc)
            .page(params[:page])
            .per(per_page(Oauth::Application))
        end

        def show
        end

        def create
          @oauth_application = Oauth::Application.new(oauth_application_params)
          @oauth_application.owner = current_admin_user

          authorize! @oauth_application, with: ::Admin::OauthApplicationPolicy

          if @oauth_application.save
            render :show, status: :created
          else
            render json: ValidationError.new("oauth_application.create", errors: @oauth_application.errors), status: :bad_request
          end
        end

        def update
          return if @oauth_application.update(oauth_application_params)

          render json: ValidationError.new("oauth_application.update", errors: @oauth_application.errors), status: :bad_request
        end

        def destroy
          return if @oauth_application.destroy

          render json: ValidationError.new("oauth_application.destroy", errors: @oauth_application.errors), status: :bad_request
        end

        private def set_application
          @oauth_application = Oauth::Application.find(params[:id])

          authorize! @oauth_application, with: ::Admin::OauthApplicationPolicy
        end

        private def oauth_application_params
          @oauth_application_params ||= params.transform_keys(&:underscore)
            .permit(:name, :redirect_uri, :confidential, scopes: [])
        end

        private def oauth_application_query_params
          params.fetch(:q, {}).permit(
            :name_cont,
            :owner_id_eq
          )
        end
      end
    end
  end
end
