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

        render json: result
      end

      private def context
        @context ||= {
          current_user: current_user,
          user_agent: request.user_agent
        }
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
