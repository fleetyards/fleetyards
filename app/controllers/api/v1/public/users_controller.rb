# frozen_string_literal: true

module Api
  module V1
    module Public
      class UsersController < ::Api::PublicBaseController
        before_action :set_user

        def show
        end

        private def set_user
          @user = User.find_by!(normalized_username: params[:username].downcase)

          authorize! @user, with: ::Public::UserPolicy
        end
      end
    end
  end
end
