# frozen_string_literal: true

json.partial! "api/v1/fleet_members/fleet_member", member: @membership, is_destroy_allowed: @is_destroy_allowed
