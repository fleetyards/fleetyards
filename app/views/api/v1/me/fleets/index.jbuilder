# frozen_string_literal: true

json.items do
  json.array! @memberships do |membership|
    fleet = membership.fleet
    capabilities = membership.capabilities

    json.id fleet.id
    json.name fleet.name
    json.slug fleet.slug

    if fleet.logo.attached?
      json.logo do
        json.partial! "api/v1/shared/file", record: fleet, attr: :logo
      end
    end

    json.role_name membership.fleet_role.name if membership.fleet_role.present?
    json.primary membership.primary
    json.member_count @member_counts.fetch(fleet.id, 0)

    # Absent rather than zero for a reader who may not see the roster: an
    # omission and a claim that nobody is online differ.
    json.online_count @online_counts.fetch(fleet.id, 0) if capabilities[:read_members]

    announcement = @latest_announcements[fleet.id]
    if announcement
      json.latest_announcement do
        json.id announcement.id
        json.excerpt MarkdownPlainText.render(announcement.body).squish.truncate(160)
        json.created_at announcement.created_at.utc.iso8601
      end
    end

    if @join_request_fleet_ids.include?(fleet.id)
      json.pending_join_requests_count @requested_counts.fetch(fleet.id, 0)
    end

    if @transfer_fleet_ids.include?(fleet.id)
      json.pending_transfers_count @transfer_counts.fetch(fleet.id, 0)
    end
  end
end
