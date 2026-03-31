# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarGroupsController < ::Api::PublicBaseController
        before_action :set_user

        def index
          @groups = HangarGroup.where(user_id: @user.id, public: true)
            .order([{sort: :asc, name: :asc}])
            .all
        end

        private def set_user
          @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

          authorize! @user, to: :show?, with: ::Public::UserPolicy
        end
      end
    end
  end
end
