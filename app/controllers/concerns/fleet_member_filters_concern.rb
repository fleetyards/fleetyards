# frozen_string_literal: true

module FleetMemberFiltersConcern
  private def member_query_params
    @member_query_params ||= params.permit(q: [
      :username_cont, :name_cont, :sorts, role_in: [], state_in: [], sorts: []
    ]).fetch(:q, {})
  end
end
