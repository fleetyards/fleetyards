# frozen_string_literal: true

module FleetMemberFiltersConcern
  private def member_query_params
    @member_query_params ||= params.permit(q: [
      :username_cont, :name_cont, :sorts,
      :accepted_at_gteq, :accepted_at_lteq,
      :invited_at_gteq, :invited_at_lteq,
      :requested_at_gteq, :requested_at_lteq,
      :declined_at_gteq, :declined_at_lteq,
      role_in: [], state_in: [], sorts: []
    ]).fetch(:q, {})
  end
end
