# frozen_string_literal: true

module Api
  module V1
    # Who is in a squadron. The rows are `FleetSquadronMembership`s, but what
    # this renders is the fleet member behind each one -- the same partial the
    # roster uses, so a squadron page and the member list describe a person the
    # same way.
    class FleetSquadronMembersController < ::Api::BaseController
      include FleetSquadronScoped
      include FleetMemberFiltersConcern

      after_action -> { pagination_header(:members) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron

      def index
        authorize! with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        scope = @fleet_squadron.accepted_fleet_memberships

        normalize_sort_params(member_query_params)
        sorts = sorting_params(FleetMembership, member_query_params["sorts"],
          allowed: FleetMembership::SQUADRON_ROSTER_SORTING_PARAMS)
        joined_sort, member_query_params["sorts"] = sorts.partition { |sort| sort.start_with?("squadron_membership_created_at ") }

        @q = scope.ransack(member_query_params)
        result = FleetMembership.where(
          FleetMembership.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
        )
        result = order_by_joined_at(result, joined_sort.first) if joined_sort.any?
        result = result
          .order(@q.result.order_values)
          .includes(
            :user,
            :fleet_role,
            fleet_squadron_memberships: {fleet_squadron: {icon_attachment: :blob}}
          )
          .joins(:user)

        @members = result_with_pagination(result, per_page(FleetMembership))
      end

      def create
        authorize! with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        @member = find_member!

        row = @fleet_squadron.fleet_squadron_memberships.new(fleet_membership: @member)

        if row.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadron_members.create", errors: row.errors), status: :bad_request
        end
      end

      def destroy
        authorize! with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        @member = find_member!

        row = @fleet_squadron.fleet_squadron_memberships.find_by!(fleet_membership: @member)

        return if row.destroy

        render json: ValidationError.new("fleet_squadron_members.destroy", errors: row.errors), status: :bad_request
      end

      def update
        authorize! with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        @member = find_member!
        row = @fleet_squadron.fleet_squadron_memberships.find_by!(fleet_membership: @member)

        if row.update(squadron_membership_params)
          head :no_content
        else
          render json: ValidationError.new("fleet_squadron_members.update", errors: row.errors), status: :bad_request
        end
      end

      # Ransack can sort by the join date only through a join it adds to the
      # inner query, which the outer one cannot see -- and that join covers
      # every squadron and team the member is on. The outer query joins this
      # squadron's own row instead, under an alias so the preloaded badges are
      # left alone.
      private def order_by_joined_at(result, sort)
        rows = FleetSquadronMembership.arel_table.alias("roster_rows")
        members = FleetMembership.arel_table
        join = members.join(rows).on(
          rows[:fleet_membership_id].eq(members[:id]).and(rows[:fleet_squadron_id].eq(@fleet_squadron.id))
        ).join_sources

        result.joins(join).order(sort.end_with?(" desc") ? rows[:created_at].desc : rows[:created_at].asc)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      # Only the accepted roster: a squadron is a working sub-unit, so somebody
      # with an unanswered invitation is not a person to post to one.
      private def find_member!
        @fleet.fleet_memberships.kept.accepted
          .includes(:user, :fleet_role)
          .joins(:user)
          .find_by!(users: {normalized_username: params[:username].to_s.downcase})
      end

      private def squadron_membership_params
        params.transform_keys(&:underscore).permit(:created_at)
      end
    end
  end
end
