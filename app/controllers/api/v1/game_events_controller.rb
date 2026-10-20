# frozen_string_literal: true

module Api
  module V1
    class GameEventsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      after_action -> { pagination_header(:game_events) }, only: [:index]

      def index
        @game_events = GameEvent.published.current
          .order(:starts_at)
          .page(page_params)
          .per(per_page(GameEvent))
      end
    end
  end
end
