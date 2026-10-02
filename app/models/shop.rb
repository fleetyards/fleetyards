# frozen_string_literal: true

# A shop UEX lists at a place. The game files carry none, so a shop exists for
# as long as UEX names it on a price: "Casaba Outlet - Everus Harbor" is the
# Casaba Outlet at Everus Harbor, made by Uex::ShopLocationMatcher.
# == Schema Information
#
# Table name: shops
#
#  id          :uuid             not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  location_id :uuid             not null
#
# Indexes
#
#  index_shops_on_location_id           (location_id)
#  index_shops_on_location_id_and_name  (location_id,name) UNIQUE
#  index_shops_on_slug                  (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#
class Shop < ApplicationRecord
  belongs_to :location
  has_many :item_prices, dependent: :nullify

  # Curated in admin: no feed carries a picture of a shop.
  has_one_attached :image

  before_validation :set_slug, if: -> { slug.blank? }

  validates :name, presence: true, uniqueness: {scope: :location_id}
  validates :slug, presence: true, uniqueness: true
  validates :image, no_vector_image: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug location_id]
  end

  # By the shop and its place, since one shop name stands at many: there are
  # ten Casaba Outlets. The place's parent tells apart two places of one name.
  private def set_slug
    base = [name, location&.name].compact.join(" ").parameterize
    candidates = [base, [name, location&.name, location&.parent&.name].compact.join(" ").parameterize]

    self.slug = candidates.find { |candidate| !Shop.where.not(id:).exists?(slug: candidate) } ||
      "#{base}-#{SecureRandom.hex(3)}"
  end
end
