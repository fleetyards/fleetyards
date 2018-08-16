# frozen_string_literal: true

class Station < ApplicationRecord
  has_many :station_shops,
           dependent: :destroy
  has_many :shops,
           through: :station_shops
  has_many :docks,
           dependent: :destroy

  has_many :images,
           as: :gallery,
           dependent: :destroy,
           inverse_of: :gallery

  belongs_to :planet

  enum station_type: %i[hub truckstop refinery cargo-station mining-station asteroid-station outpost]

  validates :name, :station_type, presence: true
  validates :name, uniqueness: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :docks, allow_destroy: true
  accepts_nested_attributes_for :station_shops, allow_destroy: true

  delegate :starsystem, to: :planet, allow_nil: true

  def self.visible
    where(hidden: false)
  end

  def image
    images.first
  end

  def ship_counts
    docks.to_a.group_by(&:max_ship_size).map do |size, _docks|
      docks.group_by(&:dock_type).map do |dock_type, docks|
        OpenStruct.new(size: size, dock_type: dock_type, count: docks.size)
      end
    end.flatten
  end

  def station_type_label
    Station.human_enum_name(:station_type, station_type)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
