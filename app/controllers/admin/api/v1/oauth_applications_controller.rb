# frozen_string_literal: true

module Admin
  module Api
    module V1
      class OauthApplicationsController < ::Admin::Api::BaseController
        before_action :set_application, only: %i[show update destroy approve reject]

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

          @oauth_application.approve

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

        def approve
          @oauth_application.reviewed_by = current_admin_user
          @oauth_application.approve

          return render :show if @oauth_application.save

          render json: ValidationError.new("oauth_application.approve", errors: @oauth_application.errors), status: :bad_request
        end

        # The reason is what the owner is shown, so a refusal without one is
        # rejected here rather than saved as an unexplained state.
        def reject
          @oauth_application.assign_attributes(
            reviewed_by: current_admin_user,
            rejection_reason: params[:rejectionReason].presence || params[:rejection_reason].presence
          )

          @oauth_application.reject

          return render :show if @oauth_application.save

          render json: ValidationError.new("oauth_application.reject", errors: @oauth_application.errors), status: :bad_request
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
            :owner_id_eq,
            :aasm_state_eq
          )
        end
      end
    end
  end
end
