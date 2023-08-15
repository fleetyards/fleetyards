# frozen_string_literal: true

module FleetMemberFiltersConcern
  private def member_query_params
    @member_query_params ||= query_params(
      :username_cont, :name_cont, sorts: [], role_in: []
    )
  end
end
