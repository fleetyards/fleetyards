# frozen_string_literal: true

# == Schema Information
#
# Table name: missions
#
#  id                 :uuid             not null, primary key
#  archived_at        :datetime
#  category           :integer          default("other"), not null
#  cover_image_preset :string
#  description        :text
#  scenario           :string
#  slug               :string           not null
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_id      :uuid             not null
#  fleet_id           :uuid             not null
#
# Indexes
#
#  index_missions_on_fleet_id_and_archived_at  (fleet_id,archived_at)
#  index_missions_on_fleet_id_and_category     (fleet_id,category)
#  index_missions_on_fleet_id_and_scenario     (fleet_id,scenario)
#  index_missions_on_fleet_id_and_slug         (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#
class Mission < ApplicationRecord
  include ActiveStorageVariants

  paginates_per 30

  belongs_to :fleet, touch: true
  belongs_to :created_by, class_name: "User"
  has_many :mission_teams, dependent: :destroy
  has_many :mission_ships, through: :mission_teams

  has_one_attached :cover_image

  enum :category, {
    other: 0,
    ship_combat: 1,
    ground_combat: 2,
    combined_combat: 3,
    mining: 4,
    salvage: 5,
    cargo_hauling: 6,
    exploration: 7
  }

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :fleet_id}

  before_save :update_slug

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  AVAILABLE_PRIVILEGES = [
    "fleet:missions:read",
    "fleet:missions:create",
    "fleet:missions:update",
    "fleet:missions:delete",
    "fleet:missions:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:missions:manage"],
    member: ["fleet:missions:read"]
  }.freeze

  DEFAULT_SORTING_PARAMS = ["title asc"]
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug fleet_id archived_at category scenario cover_image_preset created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet created_by mission_teams]
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  private def update_slug
    self.slug = generate_slug(title)
  end
end
