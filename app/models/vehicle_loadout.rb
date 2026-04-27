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
#  index_vehicle_loadouts_on_vehicle_id           (vehicle_id)
#  index_vehicle_loadouts_on_vehicle_id_and_name  (vehicle_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleLoadout < ApplicationRecord
  belongs_to :vehicle, touch: true

  has_many :vehicle_loadout_hardpoints, dependent: :destroy

  accepts_nested_attributes_for :vehicle_loadout_hardpoints, allow_destroy: true

  before_validation :set_default_name, if: -> { name.blank? }

  validates :url, presence: true
  validates :name, uniqueness: {scope: :vehicle_id}, allow_nil: true

  scope :active, -> { where(active: true) }

  def create_from_defaults!
    vehicle.model.model_hardpoints.each do |mh|
      vehicle_loadout_hardpoints.find_or_create_by!(model_hardpoint_id: mh.id) do |vlh|
        vlh.component_id = mh.component_id
      end
    end
  end

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
