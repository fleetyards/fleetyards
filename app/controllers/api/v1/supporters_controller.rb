# frozen_string_literal: true

module Api
  module V1
    class SupportersController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []

      def progress
        today = Date.current
        @goals = FundingGoal.active_for_month(today)
        @monthly_total = SupporterContribution.monthly_total(today)
        @contributions = SupporterContribution.active_in(today.beginning_of_month, today.end_of_month)
          .order(started_at: :desc, created_at: :desc)
      end
    end
  end
end
