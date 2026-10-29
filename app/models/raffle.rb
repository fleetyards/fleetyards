# frozen_string_literal: true

class Raffle < ApplicationRecord
  paginates_per 24

  # Bumped whenever the participation conditions change in meaning, so every
  # entry records which wording its user accepted.
  CONDITIONS_VERSION = "2026-10-28"

  STATUSES = %w[draft upcoming open closed drawn concluded].freeze

  # How long before the close the last-day reminder goes out.
  LAST_DAY = 1.day

  # English lives in the columns; every other locale is optional and falls
  # back to it field by field.
  TRANSLATED_ATTRIBUTES = %w[title description prize].freeze
  TRANSLATION_LOCALES = (I18n.available_locales.map(&:to_s) - ["en"]).freeze

  DEFAULT_SORTING_PARAMS = "ends_at desc"
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "startsAt asc", "startsAt desc",
    "endsAt asc", "endsAt desc",
    "createdAt asc", "createdAt desc"
  ]

  # The gift code stays out of the version history: the admin versions
  # endpoint would otherwise hand it out in plain text.
  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS, skip: [:code]

  encrypts :code

  belongs_to :drawn_by, class_name: "AdminUser", optional: true

  has_many :entries, class_name: "RaffleEntry", dependent: :delete_all, inverse_of: :raffle
  has_many :won_entries, -> { won.order(:draw_position) }, class_name: "RaffleEntry", inverse_of: false

  # A link to the raffle page that needs no sign-in and shows a draft too, for
  # someone outside the team to approve the raffle before it goes out.
  generates_token_for :preview, expires_in: 30.days

  # The first is the cover on cards and the homepage.
  has_many_attached :images

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :run_days, numericality: {only_integer: true, greater_than: 0}
  validates :claim_period_days, numericality: {only_integer: true, greater_than: 0}
  validates :prize, :code, presence: true, if: :published?
  validates :images, presence: true, if: :published?
  validates :images, no_vector_image: true
  validate :frozen_after_draw, on: :update
  validate :translations_shape

  before_validation :compute_ends_at
  before_validation :compact_translations
  before_destroy :keep_drawn_raffles, prepend: true

  scope :published, -> { where(published: true) }
  scope :running, ->(now = Time.current) { published.where(starts_at: ..now).where("raffles.ends_at > ?", now) }
  scope :start_unannounced, ->(now = Time.current) { running(now).where(start_announced_at: nil) }
  scope :last_day_unannounced, ->(now = Time.current) {
    running(now).where(last_day_announced_at: nil).where("raffles.ends_at <= ?", now + LAST_DAY)
  }

  # The one raffle the public page shows: the running one, else the next to
  # open, else the last that ran.
  def self.current(now = Time.current)
    running(now).order(:ends_at).first ||
      published.where("raffles.starts_at > ?", now).order(:starts_at).first ||
      published.order(ends_at: :desc).first
  end

  def self.ransackable_attributes(auth_object = nil)
    ["title", "published", "starts_at", "ends_at", "drawn_at", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  TRANSLATED_ATTRIBUTES.each do |attribute|
    define_method(:"localized_#{attribute}") do |locale = I18n.locale|
      translations.dig(locale.to_s, attribute).presence || public_send(attribute)
    end
  end

  def translations_list
    TRANSLATION_LOCALES.filter_map do |locale|
      next if translations[locale].blank?

      {"locale" => locale, **translations[locale]}
    end
  end

  # Replaces every translation: a locale left out of the list is dropped.
  def translations_list=(list)
    self.translations = Array(list).to_h do |entry|
      entry = entry.to_h.stringify_keys
      [entry["locale"].to_s, entry.slice(*TRANSLATED_ATTRIBUTES)]
    end
  end

  def preview_url
    "#{FRONTEND_ENDPOINT}#{Rails.application.routes.url_helpers.frontend_raffle_preview_path(generate_token_for(:preview))}"
  end

  # Stored for queries, but known before the first save too.
  def ends_at
    super || (starts_at + run_days.to_i.days if starts_at.present? && run_days.present?)
  end

  def status(now = Time.current)
    return "draft" unless published?
    return "concluded" if concluded_at.present?
    return "drawn" if drawn?
    return "upcoming" if now < starts_at
    return "open" if now < ends_at

    "closed"
  end

  def open?(now = Time.current)
    status(now) == "open"
  end

  def drawable?(now = Time.current)
    status(now) == "closed"
  end

  def drawn?
    drawn_at.present?
  end

  def concluded?
    concluded_at.present?
  end

  # In upload order, the first being the cover. Attachments carry UUIDs, so
  # neither their ids nor the association promise an order of their own.
  def ordered_images
    images.sort_by { |image| image.blob.created_at }
  end

  # From the preloaded winners on a list, a fresh query everywhere else: a
  # cached association would still name the winner a promotion just replaced.
  def current_winner
    return won_entries.find(&:current_winner?) if won_entries.loaded?

    entries.won.where(forfeited_at: nil).order(:draw_position).first
  end

  # Enough to tell two codes apart, never enough to redeem one: a code too
  # short to give away four characters safely shows none.
  def masked_code
    return if code.blank?
    return "*" * code.length if code.length < 12

    "#{"*" * (code.length - 4)}#{code.last(4)}"
  end

  def frontend_url
    "#{FRONTEND_ENDPOINT}#{Rails.application.routes.url_helpers.frontend_raffle_path(self)}"
  end

  # Ends the raffle for good: the code is on its way to a winner or nobody is
  # left to take it. The email snapshots existed only to reach a winner, so
  # they go with it.
  def conclude!(now = Time.current)
    update!(concluded_at: now)
    entries.update_all(email: nil, updated_at: now)
  end

  private def compute_ends_at
    return if starts_at.blank? || run_days.blank?

    self.ends_at = starts_at + run_days.to_i.days
  end

  private def compact_translations
    return unless translations.is_a?(Hash)

    self.translations = translations.to_h do |locale, values|
      [locale.to_s, values.is_a?(Hash) ? values.transform_keys(&:to_s).compact_blank : values]
    end.compact_blank
  end

  private def translations_shape
    unless translations.is_a?(Hash)
      errors.add(:translations, :invalid)
      return
    end

    translations.each do |locale, values|
      next if TRANSLATION_LOCALES.include?(locale) &&
        values.is_a?(Hash) &&
        (values.keys - TRANSLATED_ATTRIBUTES).empty? &&
        values.values.all?(String)

      errors.add(:translations, :invalid)
      break
    end
  end

  # A drawn raffle is the public record of who entered and who won.
  private def keep_drawn_raffles
    return unless drawn?

    errors.add(:base, :drawn)
    throw :abort
  end

  # Entrants accepted the raffle as it stood when they entered; once the order
  # is drawn, nothing that decided it may change.
  private def frozen_after_draw
    return unless drawn_at_was.present?

    %w[code starts_at run_days claim_period_days published].each do |attribute|
      errors.add(attribute, :frozen_after_draw) if will_save_change_to_attribute?(attribute)
    end
  end
end
