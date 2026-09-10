# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_loadouts
#
#  id         :uuid             not null, primary key
#  active     :boolean          default(FALSE), not null
#  name       :string           not null
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vehicle_id :uuid             not null
#
# Indexes
#
#  index_vehicle_loadouts_on_vehicle_id_and_name  (vehicle_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleLoadout < ApplicationRecord
  # `name` is whatever the owner typed and `url` is their build, and a vehicle's
  # loadouts are destroyed with the vehicle, which goes with the account.
  include ErasableVersionsConcern

  # Written only by `Api::V1::VehicleLoadoutsController`, one save per user
  # action, so every version here is a change somebody chose to make.
  #
  # `:touch` is left out for the reason `VersionedItem::RECORDED_EVENTS`
  # documents -- `touch: true` below makes this that trap in miniature -- and
  # `:destroy` for the reason `Vehicle` leaves it out: the concern above erases
  # the row in the same transaction paper_trail writes it.
  has_paper_trail on: %i[create update]

  belongs_to :vehicle, touch: true

  before_validation :set_default_name, if: -> { name.blank? }

  validates :url, presence: true
  validates :name, uniqueness: {scope: :vehicle_id}, allow_nil: true

  scope :active, -> { where(active: true) }

  def activate!
    transaction do
      vehicle.vehicle_loadouts.where.not(id: id).update_all(active: false)
      update!(active: true)
    end
  end

  def url_source
    return if url.blank?

    host = begin
      URI.parse(url).host&.downcase&.delete_prefix("www.")
    rescue
      nil
    end
    return if host.blank?

    if host.include?("erkul.games")
      "erkul"
    elsif host.include?("spviewer.eu")
      "spviewer"
    end
  end

  private def set_default_name
    base = case url_source
    when "erkul" then "Erkul Loadout"
    when "spviewer" then "SPViewer Loadout"
    else "Custom Loadout"
    end

    existing = vehicle.vehicle_loadouts.where("name LIKE ?", "#{base}%").pluck(:name)

    self.name = if existing.exclude?(base)
      base
    else
      counter = 2
      counter += 1 while existing.include?("#{base} #{counter}")
      "#{base} #{counter}"
    end
  end
end
