# frozen_string_literal: true

module Admin
  module Api
    module V1
      class RsiRequestLogsController < ::Admin::Api::BaseController
        def index
          authorize! with: ::Admin::RsiRequestLogPolicy

          rsi_request_logs_query = RsiRequestLog.ransack(query_params)
          rsi_request_logs_query.sorts = ["created_at desc"] if rsi_request_logs_query.sorts.empty?

          @rsi_request_logs = rsi_request_logs_query.result
            .page(params[:page])
            .per(per_page(RsiRequestLog))
        end

        def resolve
          authorize! with: ::Admin::RsiRequestLogPolicy

          @rsi_request_log = RsiRequestLog.find(params[:id])
          @rsi_request_log.update!(resolved: true)

          render :show
        end
      end
    end
  end
end
