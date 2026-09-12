# frozen_string_literal: true

# == Schema Information
#
# Table name: tours
#
#  id            :uuid             not null, primary key
#  cancelled_at  :datetime
#  description   :text
#  invite_token  :string           not null
#  settled_at    :datetime
#  slug          :string           not null
#  starts_at     :datetime
#  status        :string           default("open"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :uuid             not null
#
# Indexes
#
#  index_tours_on_created_by_id_and_status  (created_by_id,status)
#  index_tours_on_invite_token              (invite_token) UNIQUE
#  index_tours_on_slug                      (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
class Tour < ApplicationRecord
  include AASM

  paginates_per 30

  belongs_to :created_by, class_name: "User"

  has_one :payout_ledger, as: :subject, dependent: :destroy

  validates :title, presence: true

  before_validation :ensure_id, on: :create
  before_validation :set_invite_token, on: :create
  before_save :update_slug

  scope :active, -> { where(cancelled_at: nil) }

  DEFAULT_SORTING_PARAMS = ["createdAt desc"]
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "startsAt asc", "startsAt desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  aasm column: :status, timestamps: true, whiny_transitions: false do
    state :open, initial: true
    state :settled
    state :cancelled

    event :settle do
      transitions from: :open, to: :settled
    end

    event :reopen do
      transitions from: :settled, to: :open
    end

    event :cancel do
      transitions from: [:open, :settled], to: :cancelled
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug status starts_at created_by_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[created_by payout_ledger]
  end

  def cancelled? = cancelled_at.present?

  def rotate_invite_token!
    update!(invite_token: self.class.generate_invite_token)
  end

  def self.generate_invite_token
    SecureRandom.hex(4)
  end

  # A tour has no owning fleet to scope its slug to, so the whole site shares
  # one namespace and two people naming a trip "Jumptown Run" would collide.
  # The id prefix is what makes that impossible, the same way FleetEvent does
  # it within a fleet -- and it reads as `<short-id>-<title>` in the URL.
  private def update_slug
    base = generate_slug(title)
    prefix = id.to_s.split("-").first
    candidate = prefix.present? ? "#{prefix}-#{base}" : base
    return if slug == candidate

    self.slug = candidate
  end

  # The slug is built from the id, so it has to exist before the first save
  # rather than being handed out by the database default.
  private def ensure_id
    self.id ||= SecureRandom.uuid
  end

  private def set_invite_token
    self.invite_token ||= self.class.generate_invite_token
  end
end
