# encoding: utf-8
# frozen_string_literal: true

module Gql
  module V1
    class BaseController < ::Gql::BaseController
      def execute
        result = FleetyardsSchema.execute(
          params[:query],
          variables: variables,
          context: context,
          operation_name: params[:operationName]
        )

        if result['errors'].present?
          render json: result, status: :bad_request
        else
          render json: result
        end
      rescue GraphqlAuthenticationError => e
        render json: { errors: [{ message: e.message }] }, status: :unauthorized
      rescue GraphQL::ParseError => e
        render json: { errors: [{ message: e.message }] }, status: :bad_request
      end

      private def context
        @context ||= {
          current_user: current_user,
          user_agent: request.user_agent,
          jwt_token: jwt_token
        }
      end

      private def jwt_token
        @jwt_token ||= begin
          auth_params, _options = token_and_options(request)
          return if auth_params.blank?
          ::JsonWebToken.decode(auth_params)
        end
      end

      private def variables
        @variables ||= begin
          variable_params = params[:variables]
          case variable_params
          when String
            if variable_params.present?
              ensure_hash(JSON.parse(variable_params))
            else
              {}
            end
          when Hash, ActionController::Parameters
            variable_params
          when nil
            {}
          else
            raise ArgumentError, "Unexpected parameter: #{variable_params}"
          end
        end
      end
    end
  end
end
