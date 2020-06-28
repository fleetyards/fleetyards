# frozen_string_literal: true

json.primary @member.primary
json.partial! 'api/v1/fleet_memberships/minimal', member: @member
