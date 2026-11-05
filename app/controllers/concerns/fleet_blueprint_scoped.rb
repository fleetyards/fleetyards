# frozen_string_literal: true

module FleetBlueprintScoped
  extend ActiveSupport::Concern

  # The members who let this fleet see what they hold.
  #
  # `blueprints_filter_all` rather than "not hide", so a position added later
  # has to be opted into rather than silently counting as sharing.
  private def sharing_memberships
    @sharing_memberships ||= @fleet.fleet_memberships.kept
      .where(aasm_state: "accepted")
      .blueprints_filter_all
  end
end
