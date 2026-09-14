# frozen_string_literal: true

module Api
  module V1
    # A fleet's allies, and the requests in both directions.
    #
    # Everything here is done *for* a fleet rather than by a person, so the
    # acting party is the fleet named in the route and the privilege to act for
    # it is what `FleetAlliancePolicy` checks.
    class FleetAlliancesController < ::Api::BaseController
      include RelationshipActions
      include RelationshipsFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create destroy accept decline ignore]

      before_action :set_fleet
      before_action -> { check_fleet_allies_feature(@fleet) }
      before_action :set_relationship, only: %i[show destroy accept decline ignore]

      after_action -> { pagination_header(:allies) }, only: %i[index]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet_alliance"))
      end

      private def relation_class = ::FleetAlliance

      private def relationship_policy = ::FleetAlliancePolicy

      private def acting_party = @fleet

      private def policy_context = {context: {fleet: @fleet}}

      private def set_fleet
        @fleet = ::Fleet.kept.find_by!(slug: params[:fleet_slug])
      end

      # `ally_slug` on the member routes, `slug` in the create body.
      private def requested_party
        slug = params[:ally_slug].presence || params[:slug].presence

        ::Fleet.kept.find_by!(slug: slug)
      end
    end
  end
end
