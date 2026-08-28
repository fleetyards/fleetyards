# frozen_string_literal: true

# What a notification points at, cut down to what a client needs to fetch that
# record again.
#
# It deliberately carries no state. The notification payload is
# fragment-cached, so a status served alongside it would be a lie the moment
# the record moves on - an invite answered elsewhere would still read as open.
# The client loads the record itself and decides from there which actions still
# apply.
#
# Which endpoint a reference belongs to is not encoded here either: the same
# FleetMembership is read through `/fleets/:slug/membership` when it is the
# reader's own and through `/fleets/:slug/members/:username` when it is not,
# and the notification type is what tells the two apart.
class NotificationRecordReference
  # The associations a reference reads, so a page of notifications can preload
  # them instead of walking into one query per row. Keyed by the polymorphic
  # `record_type`, which for an STI record is the base class.
  PRELOADS = {
    "FleetMembership" => %i[fleet user],
    "FleetEvent" => %i[fleet],
    "FleetInventory" => %i[fleet]
  }.freeze

  TYPES = %w[fleet_membership fleet_event fleet_inventory vehicle hangar_sync].freeze

  def self.for(notification)
    new(notification).to_h
  end

  def self.preload(notifications)
    records = notifications.filter_map(&:record)

    PRELOADS.each do |record_type, associations|
      scoped = records.select { |record| record.class.base_class.name == record_type }

      next if scoped.empty?

      ActiveRecord::Associations::Preloader.new(records: scoped, associations:).call
    end
  end

  def initialize(notification)
    @record = notification.record
  end

  def to_h
    case record
    when FleetMembership
      {type: "fleet_membership", id: record.id, fleet_slug: record.fleet&.slug, username: record.user&.username}
    when FleetEvent
      {type: "fleet_event", id: record.id, fleet_slug: record.fleet&.slug, event_slug: record.slug}
    when FleetInventory
      {type: "fleet_inventory", id: record.id, fleet_slug: record.fleet&.slug, inventory_slug: record.slug}
    when Vehicle
      {type: "vehicle", id: record.id}
    when Imports::HangarSync
      {type: "hangar_sync", id: record.id}
    end
  end

  private attr_reader :record
end
