# frozen_string_literal: true

# The fleet and the squadron every squadron endpoint resolves, and the gate in
# front of both.
#
# A squadron lookup goes through `readable_fleet_squadrons` rather than
# `@fleet.fleet_squadrons`, so a reader whose role carries no squadron access
# gets a 404 instead of a 403 confirming the squadron exists.
module FleetSquadronScoped
  extend ActiveSupport::Concern

  private def readable_fleet_squadrons(fleet = @fleet)
    authorized_scope(fleet.fleet_squadrons, with: FleetSquadronPolicy, context: {fleet: fleet})
  end

  private def set_fleet_squadron
    @fleet_squadron = readable_fleet_squadrons.find_by!(slug: params[:slug] || params[:fleet_squadron_slug])
  end

  private def check_fleet_squadrons_feature
    return if feature_enabled?("fleet_squadrons", @fleet)

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
