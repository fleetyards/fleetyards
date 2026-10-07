# frozen_string_literal: true

module Api
  module V1
    class FleetSquadronsController < ::Api::BaseController
      include FleetSquadronScoped

      after_action -> { pagination_header(:fleet_squadrons) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy move join leave]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron, only: %i[show update destroy move join leave]

      def index
        authorize! with: FleetSquadronPolicy, context: {fleet: @fleet}

        scope = readable_fleet_squadrons.includes(:fleet_memberships, *FleetSquadron.attachment_preloads)

        query_params = params.fetch(:q, {}).permit(:name_cont, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(FleetSquadron, query_params["sorts"])

        @q = scope.ransack(query_params)

        @fleet_squadrons = result_with_pagination(@q.result(distinct: true), per_page(FleetSquadron))
      end

      def show
        authorize! @fleet_squadron

        set_viewer_rights
      end

      def create
        @fleet_squadron = @fleet.fleet_squadrons.new(fleet_squadron_params)

        authorize! @fleet_squadron

        if @fleet_squadron.save
          set_viewer_rights
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadrons.create", errors: @fleet_squadron.errors), status: :bad_request
        end
      end

      def update
        authorize! @fleet_squadron

        if @fleet_squadron.update(fleet_squadron_params)
          set_viewer_rights
          render :show
        else
          render json: ValidationError.new("fleet_squadrons.update", errors: @fleet_squadron.errors), status: :bad_request
        end
      end

      # One squadron to one place in the fleet's order -- squadrons and teams
      # are a single sequence, so `position` counts both. A lexorank move
      # writes this row alone and cannot leave two squadrons sharing a place.
      def move
        authorize! @fleet_squadron

        @fleet_squadron.move_to!(params.require(:position).to_i)

        head :no_content
      end

      # A team is open: joining one needs nobody's answer. An ordinary squadron
      # is asked for through its requests instead.
      def join
        row = @fleet_squadron.fleet_squadron_memberships.new(fleet_membership: viewer_membership)

        authorize! row, with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        if row.save
          head :no_content
        else
          render json: ValidationError.new("fleet_squadrons.join", errors: row.errors), status: :bad_request
        end
      end

      def leave
        row = @fleet_squadron.fleet_squadron_memberships.find_by!(fleet_membership: viewer_membership)

        authorize! row, with: FleetSquadronMembershipPolicy, context: {fleet: @fleet}

        if row.destroy
          head :no_content
        else
          render json: ValidationError.new("fleet_squadrons.leave", errors: row.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_squadron

        unless @fleet_squadron.destroy
          render json: ValidationError.new("fleet_squadrons.destroy", errors: @fleet_squadron.errors), status: :bad_request
        end
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      # What the reader may do to this squadron's roster. A squadron rank grants
      # rights of its own, so the fleet-wide capabilities on the membership
      # cannot answer it.
      private def set_viewer_rights
        policy = policy_for(
          record: FleetSquadronMembership.new(fleet_squadron: @fleet_squadron),
          with: FleetSquadronMembershipPolicy,
          context: {fleet: @fleet}
        )

        @squadron_capabilities = {
          manage_members: policy.apply(:create?),
          manage_ranks: policy.apply(:manage_ranks?)
        }

        @viewer_squadron_role = policy.actor_rank

        membership = viewer_membership
        @viewer_is_member = membership.present? && @fleet_squadron.fleet_squadron_memberships.exists?(fleet_membership: membership)
        @viewer_request = membership && @fleet_squadron.fleet_squadron_requests.find_by(fleet_membership: membership)

        # Whatever already commits the reader elsewhere: the ordinary squadron
        # they hold, or the one they are waiting to hear back from. Either
        # rules out asking for this one.
        if membership.present? && @fleet_squadron.exclusive? && !@viewer_is_member && @viewer_request.blank?
          @viewer_exclusive_squadron = membership.exclusive_squadron(except: @fleet_squadron)
          @viewer_requested_squadron = membership.requested_squadron(except: @fleet_squadron)
        end

        @pending_request_count = @fleet_squadron.fleet_squadron_requests.pending.count if @squadron_capabilities[:manage_members]
      end

      private def viewer_membership
        return @viewer_membership if defined?(@viewer_membership)

        @viewer_membership = @fleet.fleet_memberships.kept.accepted.find_by(user: current_resource_owner)
      end

      private def fleet_squadron_params
        authorized(params, with: FleetSquadronPolicy, context: {fleet: @fleet})
      end
    end
  end
end
