# frozen_string_literal: true

json.array! @fleet_roles, partial: "api/v1/fleet_roles/fleet_role", as: :fleet_role
