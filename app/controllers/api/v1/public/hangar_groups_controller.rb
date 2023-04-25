# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarGroupsController < ::Api::PublicBaseController
        def index
          authorize! :public, :api_hangar_groups

          user = User.find_by!("lower(username) = ?", params.fetch(:hangar_username, "").downcase)

          @groups = HangarGroup.where(user_id: user.id, public: true)
            .order([{ sort: :asc, name: :asc }])
            .all
        end
      end
    end
  end
end
