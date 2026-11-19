# frozen_string_literal: true

module Api
  module V1
    class FeedbacksController < ::Api::BaseController
      def create
        @feedback = current_user.feedbacks.new(feedback_params)
        authorize! @feedback, with: FeedbackPolicy

        if @feedback.save
          render :show, status: :created
        else
          render json: ValidationError.new("feedbacks.create", errors: @feedback.errors), status: :bad_request
        end
      end

      private def feedback_params
        params.permit(:message, :feature_name, :page_path)
      end
    end
  end
end
