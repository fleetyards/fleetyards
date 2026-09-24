# frozen_string_literal: true

json.cache! ["v4", member] do
  json.partial! "api/v1/fleet_members/base", member: member
end

# Outside the fragment, which every reader shares: a role may read the roster
# without reading squadrons. Rendered fresh, the badges also follow a squadron
# renamed or reordered without touching the membership.
if squadrons_readable_in?(member.fleet_id)
  json.squadrons do
    # Ordinary squadrons before teams, then the fleet's own order. A member holds
    # at most one ordinary squadron, so the first of these is the one the roster
    # badges them with -- their squadron, not whichever team sorts first.
    squadron_memberships = member.fleet_squadron_memberships.sort_by do |squadron_membership|
      squadron = squadron_membership.fleet_squadron
      [squadron.team? ? 1 : 0, squadron.rank]
    end

    json.array! squadron_memberships do |squadron_membership|
      squadron = squadron_membership.fleet_squadron
      json.id squadron.id
      json.name squadron.name
      json.slug squadron.slug
      json.color squadron.color
      json.team squadron.team
      json.membership_created_at squadron_membership.created_at.utc.iso8601

      # The roster draws the mark rather than the name, and at that size the mark
      # is the square one.
      if squadron.icon.attached?
        json.icon do
          json.partial! "api/v1/shared/file", record: squadron, attr: :icon
        end
      else
        json.icon nil
      end
    end
  end
end

# Outside the fragment: the key is the membership, and nothing about presence
# touches it. Absent rather than false when the reader is not entitled to an
# answer -- an omission and a claim that somebody is offline differ.
online = online_status_for(member.user)
json.online online unless online.nil?

json.is_destroy_allowed(local_assigns.fetch(:is_destroy_allowed, false))

if local_assigns.fetch(:with_capabilities, false)
  json.capabilities member.capabilities.transform_keys { |key| key.to_s.camelize(:lower) }
end
