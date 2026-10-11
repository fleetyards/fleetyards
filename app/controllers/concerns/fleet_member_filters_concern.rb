# frozen_string_literal: true

module FleetMemberFiltersConcern
  # Facts only a roster reader may ask about. Anywhere else they would turn a
  # count, which a fleet may publish, into who is inactive, unverified or
  # unlinked.
  ROSTER_FILTERS = %i[inactive_since verified_eq without_rsi_handle without_discord without_squadron].freeze

  private def roster_filters?
    false
  end

  private def member_query_params
    @member_query_params ||= params.permit(q: [
      :search_cont, :username_cont, :nickname_cont, :name_cont, :s, :sorts,
      :accepted_at_gteq, :accepted_at_lteq,
      :squadron_membership_created_at_gteq, :squadron_membership_created_at_lteq,
      :invited_at_gteq, :invited_at_lteq,
      :requested_at_gteq, :requested_at_lteq,
      :declined_at_gteq, :declined_at_lteq,
      *(roster_filters? ? ROSTER_FILTERS : []),
      role_in: [], state_in: [], squadron_slug_in: [], s: [], sorts: []
    ]).fetch(:q, {}).tap do |query|
      search = query.delete(:search_cont)
      # The real association path, not the `username` alias: ransack does not
      # resolve an alias inside an `_or_` chain and would query a
      # `fleet_memberships.username` column that does not exist.
      query[:user_username_or_nickname_cont] = search if search.present?
    end
  end
end
