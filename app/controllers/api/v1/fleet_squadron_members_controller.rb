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

      ROSTER_ROW_SORTS = ["squadron_membership_created_at ", "squadron_rank "].freeze

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
        # Leaders first: a squadron is read top down, so its own ranks are the
        # order it opens on.
        sorts = sorting_params(FleetMembership, member_query_params["sorts"], ["squadron_rank asc"],
          allowed: FleetMembership::SQUADRON_ROSTER_SORTING_PARAMS)
        roster_sorts, member_query_params["sorts"] = sorts.partition { |sort| sort.start_with?(*ROSTER_ROW_SORTS) }
        joined_from = member_query_params.delete("squadron_membership_created_at_gteq")
        joined_until = member_query_params.delete("squadron_membership_created_at_lteq")

        @q = scope.ransack(member_query_params)
        result = FleetMembership.where(
          FleetMembership.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
        )
        result = on_roster_row(result, sorts: roster_sorts, from: joined_from, until_date: joined_until)
        result = result
          .order(@q.result.order_values)
          .order(User.arel_table[:normalized_username].asc)
          .includes(*FleetMembership::ROSTER_PRELOADS)
          .joins(:user)

        @members = result_with_pagination(result, per_page(FleetMembership))
      end

      def create
        row = @fleet_squadron.fleet_squadron_memberships.new

        authorize! row, with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        @member = find_member!
        row.fleet_membership = @member

        if row.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadron_members.create", errors: row.errors), status: :bad_request
        end
      end

      # Asked twice: once whether the caller manages this roster at all, before
      # the username is looked up, so an outsider learns nothing about who is
      # in it; then whether they outrank this particular member.
      def destroy
        authorize! with: FleetSquadronMembershipPolicy, to: :create?, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        @member = find_member!

        row = @fleet_squadron.fleet_squadron_memberships.find_by!(fleet_membership: @member)

        authorize! row, with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        return if row.destroy

        render json: ValidationError.new("fleet_squadron_members.destroy", errors: row.errors), status: :bad_request
      end

      def update
        authorize! with: FleetSquadronMembershipPolicy, to: :create?, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        @member = find_member!
        row = @fleet_squadron.fleet_squadron_memberships.find_by!(fleet_membership: @member)
        row.assign_attributes(squadron_membership_params)

        authorize! row, with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        if row.save
          head :no_content
        else
          render json: ValidationError.new("fleet_squadron_members.update", errors: row.errors), status: :bad_request
        end
      end

      # The join date and the rank belong to this squadron's own row. Ransack
      # reaches them only through a join over every squadron and team the
      # member is on -- a team joined last week would pass a filter this
      # squadron's date fails -- and a sort it adds there is invisible to the
      # outer query. So the outer query joins this squadron's row itself, under
      # an alias that leaves the preloaded badges alone, and filters and sorts
      # on that.
      private def on_roster_row(result, sorts:, from:, until_date:)
        rows = FleetSquadronMembership.arel_table.alias("roster_rows")
        ranks = FleetSquadronRole.arel_table.alias("roster_ranks")
        members = FleetMembership.arel_table
        join = members
          .join(rows).on(rows[:fleet_membership_id].eq(members[:id]).and(rows[:fleet_squadron_id].eq(@fleet_squadron.id)))
          .join(ranks).on(ranks[:id].eq(rows[:fleet_squadron_role_id]))
          .join_sources

        result = result.joins(join)
        result = result.where(rows[:created_at].gteq(Time.zone.parse(from))) if from.present?
        result = result.where(rows[:created_at].lteq(Time.zone.parse(until_date))) if until_date.present?

        sorts.reduce(result) do |sorted, sort|
          column = sort.start_with?("squadron_rank ") ? ranks[:position] : rows[:created_at]
          sorted.order(sort.end_with?(" desc") ? column.desc : column.asc)
        end
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
        params.transform_keys(&:underscore).permit(:created_at, :fleet_squadron_role_id)
      end
    end
  end
end
