# frozen_string_literal: true

module FleetMemberFiltersConcern
  private def member_query_params
    @member_query_params ||= params.permit(q: [
      :username_cont, :name_cont, role_in: []
    ]).fetch(:q, {})
  end
end
