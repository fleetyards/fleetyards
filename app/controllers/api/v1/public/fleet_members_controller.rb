# frozen_string_literal: true

module Api
  module V1
    module Public
      # A fleet's roster, as an allied fleet sees it.
      #
      # A separate controller and a separate partial rather than the fleet's own
      # `FleetMembersController` behind a widened policy. That one renders each
      # member's Discord, YouTube, Twitch and Guilded handles, their RSI handle,
      # their homepage, their latitude and longitude, their current system and
      # when they were last active -- everything a fleet needs to manage its own
      # people. Handing that to another organisation because two admins shook
      # hands is not "showing the member list", and a policy in front of it
      # would hand over every field anybody ever adds to it.
      class FleetMembersController < ::Api::PublicBaseController
        before_action :set_fleet

        after_action -> { pagination_header(:members) }, only: %i[index]

        rescue_from ActiveRecord::RecordNotFound, ActionPolicy::Unauthorized do |_exception|
          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
        end

        def index
          result = @fleet.fleet_memberships
            .kept
            .accepted
            .includes(:fleet_role, {user: {avatar_attachment: :blob}})
            .joins(:user)
            .order("users.username ASC")

          @members = result_with_pagination(result, per_page(FleetMembership))
        end

        private def set_fleet
          @fleet = Fleet.kept.find_by!(slug: params[:fleet_slug])

          authorize! @fleet, to: :show_members?, with: ::Public::FleetPolicy
        end
      end
    end
  end
end
