# frozen_string_literal: true

module Api
  module V2
    module Hangar
      module Public
        class GroupsController < ::Api::V2::BaseController
          before_action :authenticate_user!, only: []

          def index
            authorize! :public, :api_hangar_groups

            user = User.find_by!('lower(username) = ?', params.fetch(:username, '').downcase)

            @groups = HangarGroup.where(user_id: user.id, public: true)
              .order([{ sort: :asc, name: :asc }])
              .all
          end
        end
      end
    end
  end
end
