# frozen_string_literal: true

module Gql
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session

    def execute
      result = if params[:_json].present? && params[:_json].is_a?(Array)
                 batch_result
               else
                 single_result
               end

      render json: result
    rescue GraphQL::ParseError, GraphqlArgumentError => e
      render json: { errors: [{ message: e.message }] }, status: :bad_request
    end

    private def single_result
      query = prepare_query(params)
      FleetyardsSchema.execute(query)
    end

    private def batch_result
      queries = params[:_json].map do |param|
        unless [Hash, ActionController::Parameters].include?(param.class)
          raise GraphqlArgumentError, "Unexpected parameter: #{param}"
        end
        prepare_query(param)
      end
      FleetyardsSchema.multiplex(queries)
    end

    private def prepare_query(prepared_params)
      {
        variables: ensure_hash(prepared_params[:variables]),
        query: prepared_params[:query],
        operation_name: prepared_params[:operationName],
        context: context
      }
    end

    private def context
      {
        current_user: current_api_user
      }
    end

    private def ensure_hash(ambiguous_param)
      case ambiguous_param
      when String
        if ambiguous_param.present?
          ensure_hash(JSON.parse(ambiguous_param))
        else
          {}
        end
      when Hash, ActionController::Parameters
        ambiguous_param
      when nil
        {}
      else
        raise GraphqlArgumentError, "Unexpected parameter: #{ambiguous_param}"
      end
    end
  end
end
