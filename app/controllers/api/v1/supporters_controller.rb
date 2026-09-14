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
        # Anonymity means not being named here. A row rendered as "Anonymous" is
        # still being listed, which is the thing it asked not to be -- and a
        # column of identical "Anonymous" entries tells a reader nothing anyway.
        # The money still counts: @monthly_total is deliberately unfiltered.
        @contributions = SupporterContribution.active_now(today)
          .where(anonymous: false)
          .includes(:user)
          .order(started_at: :desc, created_at: :desc)
      end
    end
  end
end
