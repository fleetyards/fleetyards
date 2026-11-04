# frozen_string_literal: true

# Which of a fleet's contracts the caller reaches. A draft is not a job offer
# yet, so only those who could publish it see it, along with the author of a
# personal one.
module FleetContractScoped
  extend ActiveSupport::Concern

  private def visible_fleet_contracts
    scope = @fleet.fleet_contracts

    return scope if allowed_to?(:manage?, @fleet, with: FleetContractPolicy)

    own_personal_drafts = scope.draft.personal.where(created_by: current_resource_owner)

    narrow_to_squadron_access(scope.where.not(aasm_state: "draft").or(own_personal_drafts))
  end
end
