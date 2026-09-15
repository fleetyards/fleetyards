# frozen_string_literal: true

# == Schema Information
#
# Table name: missions
#
#  id                 :uuid             not null, primary key
#  archived_at        :datetime
#  category           :integer          default(0), not null
#  cover_image_preset :string
#  description        :text
#  scenario           :string
#  slug               :string           not null
#  status             :string           default("draft"), not null
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
#  index_missions_on_fleet_id_and_status       (fleet_id,status)
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

  # A mission the create button wrote and nobody has offered to the fleet yet,
  # and one that has been. Named here so the API schema reads them from the
  # model rather than repeating the strings.
  STATUSES = {draft: "draft", published: "published"}.freeze

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :fleet_id}
  validates :status, inclusion: {in: STATUSES.values}

  before_validation :assign_default_title, on: :create

  before_save :update_slug

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :published, -> { where(status: STATUSES[:published]) }
  scope :draft, -> { where(status: STATUSES[:draft]) }

  # A draft belongs to whoever is writing it; the rest of the fleet sees a
  # mission once it is published. Anyone who could publish it sees every draft,
  # which the caller passes in -- that answer lives in the policy.
  scope :visible_to, ->(user, manage: false) {
    next all if manage
    next published if user.blank?

    where(status: STATUSES[:published]).or(where(created_by_id: user.id))
  }

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
    %w[title slug fleet_id archived_at status category scenario cover_image_preset created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet created_by mission_teams]
  end

  def archived?
    archived_at.present?
  end

  def draft?
    status == STATUSES[:draft]
  end

  def published?
    status == STATUSES[:published]
  end

  # Nothing to announce and no signups to keep: a mission nobody ever published
  # is removed outright rather than archived, so abandoning a create leaves no
  # trace. A published one keeps the archive step it has always had.
  def publish!
    update!(status: STATUSES[:published])
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
  # The create button writes a draft before the author has typed anything, so it
  # sends no title at all and this fills one in. Two of them in a fleet would
  # arrive under the same name, so the second is numbered rather than refused --
  # the author is on their way to the editor to rename it anyway.
  #
  # Only ever the title this generates. One somebody actually typed is theirs
  # alone: it is checked like any other, and a duplicate is an error rather than
  # something quietly renamed behind them.
  private def assign_default_title
    return if title.present?

    base = I18n.t("defaults.mission.title")

    self.title = title_taken?(base) ? "#{base} #{next_free_suffix(base)}" : base
  end

  private def next_free_suffix(base)
    (2..).find { |candidate| !title_taken?("#{base} #{candidate}") }
  end

  private def title_taken?(candidate)
    self.class.where(fleet_id:).exists?(["lower(title) = ?", candidate.downcase])
  end
end
