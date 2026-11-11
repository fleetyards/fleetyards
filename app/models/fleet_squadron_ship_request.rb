# frozen_string_literal: true

# A squadron's leadership asking a member for one of their ships. Only the
# member can say yes: accepting adds the ship to what they give the squadron,
# declining is a plain delete. Nobody else can put a member's ship into a
# squadron.
class FleetSquadronShipRequest < ApplicationRecord
  belongs_to :fleet_squadron_membership
  belongs_to :vehicle
  belongs_to :requested_by, class_name: "FleetMembership", optional: true

  has_one :fleet_squadron, through: :fleet_squadron_membership
  has_one :fleet_membership, through: :fleet_squadron_membership

  validates :vehicle_id, uniqueness: {scope: :fleet_squadron_membership_id, message: :already_requested}

  validate :vehicle_belongs_to_the_member
  validate :vehicle_is_shared_with_the_fleet
  validate :vehicle_is_not_already_given, on: :create

  after_create_commit :notify_member

  # Leaving the fleet discards the membership rather than deleting it, so a
  # request to somebody who has since left is still a row.
  scope :open, -> { joins(fleet_squadron_membership: :fleet_membership).merge(FleetMembership.kept.accepted) }

  def accept!
    transaction do
      fleet_squadron_membership.fleet_squadron_membership_vehicles.find_or_create_by!(vehicle:)
      destroy!
    end

    notify_requester_accepted
  end

  private def notify_member
    user = fleet_membership&.user
    return if user.blank?

    I18n.with_locale(user.notification_locale) do
      Notification.notify!(
        user:,
        type: :fleet_squadron_ship_request_received,
        title: I18n.t("notifications.fleet_squadron_ship_request_received.title",
          username: requested_by&.user&.username, ship: ship_label, squadron: fleet_squadron.name),
        link: "#{squadron_path}my-ships/",
        icon: "fa-duotone fa-rocket-launch",
        record: fleet_squadron
      )
    end
  end

  private def notify_requester_accepted
    user = requested_by&.user
    return if user.blank? || requested_by.discarded?

    I18n.with_locale(user.notification_locale) do
      Notification.notify!(
        user:,
        type: :fleet_squadron_ship_request_accepted,
        title: I18n.t("notifications.fleet_squadron_ship_request_accepted.title",
          username: fleet_membership.user&.username, ship: ship_label, squadron: fleet_squadron.name),
        link: squadron_path,
        icon: "fa-duotone fa-rocket-launch",
        record: fleet_squadron
      )
    end
  end

  private def ship_label
    vehicle.name.presence || vehicle.model&.name
  end

  private def squadron_path
    "/fleets/#{fleet_squadron.fleet.slug}/squadrons/#{fleet_squadron.slug}/"
  end

  private def vehicle_belongs_to_the_member
    return if vehicle.blank? || fleet_squadron_membership.blank?
    return if vehicle.user_id == fleet_membership&.user_id

    errors.add(:vehicle, :not_owned)
  end

  # Asking for a ship the fleet cannot see would tell the officer it exists.
  private def vehicle_is_shared_with_the_fleet
    return if vehicle.blank? || fleet_squadron.blank?
    return if FleetVehicle.exists?(fleet_id: fleet_squadron.fleet_id, vehicle_id:)

    errors.add(:vehicle, :not_in_fleet)
  end

  private def vehicle_is_not_already_given
    return if vehicle.blank? || fleet_squadron.blank?

    given = FleetSquadron.vehicle_ids_for(fleet_id: fleet_squadron.fleet_id, squadron_ids: [fleet_squadron.id])
      .where("squadron_rows.id": fleet_squadron_membership_id)
      .exists?(id: vehicle_id)

    errors.add(:vehicle, :already_given) if given
  end
end
