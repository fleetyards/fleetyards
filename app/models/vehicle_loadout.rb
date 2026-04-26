# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_loadouts
#
#  id           :uuid             not null, primary key
#  active       :boolean          default(FALSE), not null
#  erkul_url    :string
#  name         :string           not null
#  spviewer_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  vehicle_id   :uuid             not null
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
  belongs_to :vehicle

  has_many :vehicle_loadout_hardpoints, dependent: :destroy

  accepts_nested_attributes_for :vehicle_loadout_hardpoints, allow_destroy: true

  attribute :url, :string

  before_validation :detect_url_source, if: -> { url.present? }
  before_validation :set_default_name, if: -> { name.blank? }

  validates :name, presence: true, uniqueness: {scope: :vehicle_id}

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

  private def detect_url_source
    uri = begin
      URI.parse(url)
    rescue
      nil
    end
    return if uri.blank? || uri.host.blank?

    host = uri.host.downcase.delete_prefix("www.")

    if host.include?("erkul.games")
      self.erkul_url = url
    elsif host.include?("spviewer.eu")
      self.spviewer_url = url
    end
  end

  private def set_default_name
    self.name = if erkul_url.present?
      "Erkul Loadout"
    elsif spviewer_url.present?
      "SPViewer Loadout"
    else
      "Loadout #{vehicle.vehicle_loadouts.count + 1}"
    end
  end
end
