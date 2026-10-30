# frozen_string_literal: true

module Api
  module V1
    class MyRaffleEntriesController < ::Api::BaseController
      after_action -> { pagination_header(:entries) }, only: [:index]

      def index
        authorize! with: ::RaffleEntryPolicy

        @entries = authorized_scope(RaffleEntry.all, with: ::RaffleEntryPolicy)
          .includes(:raffle)
          .order(created_at: :desc)
          .page(page_params)
          .per(per_page(RaffleEntry))
      end
    end
  end
end
