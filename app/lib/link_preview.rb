# frozen_string_literal: true

# What a link preview may say about a fleet's event, contract or tour. Previews
# are fetched by an unauthenticated crawler and shown to whoever the link is
# pasted to, so an item only names itself when every member of its fleet may
# see it; anything narrower reads as a generic item of the fleet.
class LinkPreview
  attr_reader :title, :image

  def initialize(title:, image: nil)
    @title = title
    @image = image
  end

  def self.for_fleet_event(event)
    return restricted("fleet_event", event.fleet) if event.draft? || !event.discord_guild_wide?

    new(title: event.title, image: cover_or_logo(event.cover_image, event.fleet))
  end

  def self.for_fleet_contract(contract)
    return restricted("fleet_contract", contract.fleet) if contract.draft? || !contract.members_only?

    new(title: contract.display_title, image: cover_or_logo(contract.cover_image, contract.fleet))
  end

  # A fleet's tour is open to all of its members. A standalone one is only open
  # to its organiser and participants, unless the link carries its invite token,
  # which is the credential that lets anyone holding it join.
  def self.for_tour(tour, via_invite: false)
    image = attached(tour.fleet&.logo)

    return new(title: I18n.t("title.link_preview.tour_invite", tour: tour.title), image:) if via_invite
    return new(title: I18n.t("title.link_preview.tour")) if tour.fleet.blank?

    new(title: tour.title, image:)
  end

  def self.restricted(kind, fleet)
    new(title: I18n.t("title.link_preview.#{kind}", fleet: fleet.name), image: attached(fleet.logo))
  end

  def self.cover_or_logo(cover, fleet)
    attached(cover) || attached(fleet.logo)
  end

  def self.attached(attachment)
    attachment if attachment&.attached?
  end

  private_class_method :restricted, :cover_or_logo, :attached
end
