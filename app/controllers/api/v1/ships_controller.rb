module Api
  module V1
    class ShipsController < BaseController
      before_filter :authenticate_user!, only: []
        skip_authorization_check only: [:index]

      def index
        ships = Ship.all
          .order("ships.name asc")
        render json: ships, status: :ok
      end
    end
  end
end
