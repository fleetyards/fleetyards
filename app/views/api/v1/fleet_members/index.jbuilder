# frozen_string_literal: true

json.array! @members, partial: "api/v1/fleet_members/fleet_member", as: :member
