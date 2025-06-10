# frozen_string_literal: true

module Oauth
  class AuthorizationsController < Doorkeeper::ApplicationController
    before_action :authenticate_resource_owner!

    def new
      authorize! :read, :oauth_authorizations

      if pre_auth.authorizable?
        render_success
      else
        render_error
      end
    end

    def create
      authorize! :create, :oauth_authorizations

      redirect_or_render(authorize_response)
    end

    def destroy
      authorize! :destroy, :oauth_authorizations

      redirect_or_render(authorization.deny)
    rescue Doorkeeper::Errors::InvalidTokenStrategy => e
      error_response = get_error_response_from_exception(e)

      respond_to do |format|
        format.html do
          render :error, locals: {error_response: error_response}
        end
        format.json do
          render json: error_response.body, status: :bad_request
        end
      end
    end

    private def render_success
      if skip_authorization? || (matching_token? && pre_auth.client.application.confidential?)
        redirect_or_render(authorize_response)
      else
        respond_to do |format|
          format.html do
            render "frontend/index", layout: "application"
            # render :new
          end
          format.json do
            @pre_auth = pre_auth
            render :pre_authorization, layout: false
          end
        end
      end
    end

    private def render_error
      respond_to do |format|
        format.html do
          render "frontend/index", layout: "application"
          # render :error, locals: {error_response: pre_auth.error_response}
        end
        format.json do
          render json: pre_auth.error_response.body,
            status: :bad_request
        end
      end
    end

    # Active access token issued for the same client and resource owner with
    # the same set of the scopes exists?
    private def matching_token?
      Doorkeeper.config.access_token_model.matching_token_for(
        pre_auth.client,
        current_resource_owner,
        pre_auth.scopes
      )
    end

    private def redirect_or_render(auth)
      if auth.redirectable?
        if pre_auth.form_post_response?
          respond_to do |format|
            format.html { render :form_post }
            format.json do
              render(
                json: {status: :post, redirect_uri: pre_auth.redirect_uri, body: auth.body},
                status: auth.status
              )
            end
          end
        else
          respond_to do |format|
            format.html { redirect_to auth.redirect_uri, allow_other_host: true }
            format.json do
              render(
                json: {status: :redirect, redirect_uri: auth.redirect_uri},
                status: auth.status
              )
            end
          end
        end
      else
        render json: auth.body, status: auth.status
      end
    end

    private def pre_auth
      @pre_auth ||= ::Doorkeeper::OAuth::PreAuthorization.new(
        Doorkeeper.configuration,
        pre_auth_params,
        current_resource_owner
      )
    end

    private def pre_auth_params
      params.slice(*pre_auth_param_fields).permit(*pre_auth_param_fields)
    end

    private def pre_auth_param_fields
      custom_access_token_attributes + %i[
        client_id
        code_challenge
        code_challenge_method
        response_type
        response_mode
        redirect_uri
        scope
        state
      ]
    end

    private def custom_access_token_attributes
      Doorkeeper.config.custom_access_token_attributes.map(&:to_sym)
    end

    private def authorization
      @authorization ||= strategy.request
    end

    private def strategy
      @strategy ||= server.authorization_request(pre_auth.response_type)
    end

    private def authorize_response
      @authorize_response ||= begin
        return pre_auth.error_response unless pre_auth.authorizable?

        context = build_context(pre_auth: pre_auth)
        before_successful_authorization(context)

        auth = strategy.authorize

        context = build_context(auth: auth)
        after_successful_authorization(context)

        auth
      end
    end

    private def build_context(**attributes)
      Doorkeeper::OAuth::Hooks::Context.new(**attributes)
    end

    private def before_successful_authorization(context = nil)
      Doorkeeper.config.before_successful_authorization.call(self, context)
    end

    private def after_successful_authorization(context)
      Doorkeeper.config.after_successful_authorization.call(self, context)
    end
  end
end
