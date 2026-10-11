# frozen_string_literal: true

module Api
  module V1
    # The roster's loose ends, for whoever can act on them. Each check is a
    # count and its first few rows; the members list, filtered the same way,
    # holds the rest. A check the fleet does not use, or the reader may not
    # see, is null rather than empty, so the page can tell "nothing wrong" from
    # "not asked".
    class FleetMemberHealthController < ::Api::BaseController
      DEFAULT_INACTIVE_DAYS = 30
      JOIN_REQUEST_WAIT = 7.days
      INVITATION_WAIT = 14.days
      SAMPLE = 5

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]

      before_action :set_fleet

      def show
        authorize! with: FleetMembershipPolicy, to: :health?, context: {fleet: @fleet}

        @members = @fleet.fleet_memberships.kept.accepted
        @inactive_days = inactive_days
        @leader_role_ids = @fleet.leader_roles.ids.to_set

        admin_role = @fleet.fleet_roles.find_by(permanent: true)
        @admins = check(@members.where(fleet_role: admin_role), order: :accepted_at)
        # Who a promotion would make the second admin: promoting moves a member
        # one rank up, so only the rank right below can get there in one step.
        @admin_candidates = promotion_candidates(admin_role) if admin_role && @admins[:total_count] <= 1
        @empty_roles = empty_roles if can?(:read_roles)

        if @fleet.rsi_sid.present?
          @unverified = check(@members.where(verified: false), order: :accepted_at)
        else
          @without_rsi_handle = check(@members.without_rsi_handle, order: :accepted_at)
        end

        # Whole days, as the member list's filter counts them, so "show all"
        # lists exactly the members counted here.
        @inactive = check(@members.inactive_since(@inactive_days.days.ago.utc.to_date), order: inactive_order)
        @join_requests = check(@fleet.fleet_memberships.kept.requested.where(requested_at: ...JOIN_REQUEST_WAIT.ago), order: :requested_at)
        @invitations = check(@fleet.fleet_memberships.kept.invited.where(invited_at: ...INVITATION_WAIT.ago), order: :invited_at)
        @invite_urls = invite_urls if can?(:read_invites)

        @without_discord = check(@members.without_discord, order: :accepted_at) if discord_roles?

        if @fleet.squadrons_enabled? && can?(:read_squadrons)
          @without_squadron = check(@members.without_squadron, order: :accepted_at)
          @empty_squadrons = empty_squadrons
        end

        @hidden_ships_count = @members.ships_filter_hide.count
      end

      private def check(scope, order:)
        {
          total_count: scope.count,
          items: scope.includes(:fleet_role, :inviter, user: [:omniauth_connections, {avatar_attachment: :blob}])
            .joins(:user)
            .order(order, :id)
            .limit(sample)
        }
      end

      # The dashboard shows a number, not the rows, and asks for none.
      private def sample
        @sample ||= params[:sample].present? ? params[:sample].to_i.clamp(0, SAMPLE) : SAMPLE
      end

      # The fleet's leaders first: an officer who stopped showing up leaves a gap
      # a member does not. Then whoever has been gone longest, never-active
      # accounts before all.
      private def inactive_order
        leader_ids = @leader_role_ids.to_a

        Arel.sql(ActiveRecord::Base.sanitize_sql_array([
          "CASE WHEN fleet_memberships.fleet_role_id IN (?) THEN 0 ELSE 1 END, users.last_active_at ASC NULLS FIRST",
          leader_ids.presence || [nil]
        ]))
      end

      private def promotion_candidates(role)
        lower_role = @fleet.fleet_roles.where("fleet_roles.rank > ?", role.rank).reorder(:rank).first
        return [] if lower_role.nil?

        @members.where(fleet_role: lower_role)
          .includes(:fleet_role, :inviter, user: [:omniauth_connections, {avatar_attachment: :blob}])
          .joins(:user)
          .order(Arel.sql("users.last_active_at DESC NULLS LAST"), :id)
          .limit(sample)
      end

      private def empty_roles
        @fleet.fleet_roles.ranked.where.not(id: @members.where.not(fleet_role_id: nil).select(:fleet_role_id))
      end

      # Links that no longer let anyone in are clutter; one without an expiry or
      # a limit lets in whoever finds it.
      private def invite_urls
        now = Time.current
        scope = @fleet.fleet_invite_urls.where(
          "fleet_invite_urls.expires_after < :now OR fleet_invite_urls.limit <= 0 " \
          "OR (fleet_invite_urls.expires_after IS NULL AND fleet_invite_urls.limit IS NULL)",
          now:
        )

        {total_count: scope.count, items: scope.includes(:user).order(:created_at, :id).limit(sample)}
      end

      private def empty_squadrons
        scope = @fleet.fleet_squadrons.where.not(
          id: FleetSquadronMembership.where(fleet_membership_id: @members.select(:id)).select(:fleet_squadron_id)
        )

        {total_count: scope.count, items: scope.reorder(:rank).limit(sample)}
      end

      # Only a fleet that hands out Discord roles needs its members linked.
      private def discord_roles?
        setting = @fleet.fleet_notification_setting
        return false if setting&.discord_guild_id.blank?

        setting.discord_member_role_id.present? || @fleet.fleet_roles.where.not(discord_role_id: [nil, ""]).exists?
      end

      private def can?(capability)
        current_fleet_membership&.has_access?(FleetMembership::CAPABILITY_PRIVILEGES.fetch(capability))
      end

      private def inactive_days
        days = params[:inactive_days].presence&.to_i
        (days.nil? || days < 1) ? DEFAULT_INACTIVE_DAYS : days
      end

      private def current_fleet_membership
        @current_fleet_membership ||= current_resource_owner.fleet_memberships.kept.accepted.find_by(fleet: @fleet)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end
