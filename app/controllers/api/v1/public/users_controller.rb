# frozen_string_literal: true

module Api
  module V1
    module Public
      class UsersController < ::Api::PublicBaseController
        def show
          @user = User.find_by!(normalized_username: params[:username].downcase, public_hangar: true)
        end
      end
    end
  end
end
