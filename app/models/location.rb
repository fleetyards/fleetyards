# frozen_string_literal: true

# A place in the game: a star system, a star, a planet or moon, a station, a
# city, an outpost, an asteroid base. Loaded from the starmap -- see
# `ScData::Parser::StarmapParser` for how the export's records become places.
# == Schema Information
#
# Table name: locations
#
#  id                         :uuid             not null, primary key
#  always_shown               :boolean          default(FALSE), not null
#  color                      :string
#  description                :text
#  game_type                  :string
#  kind                       :string
#  mission_template_refs      :text             default([]), not null, is an Array
#  name                       :string
#  quantum_travel_destination :boolean          default(FALSE), not null
#  resources                  :jsonb            not null
#  sc_key                     :string           not null
#  sc_refs                    :text             default([]), not null, is an Array
#  shown_on_starmap           :boolean          default(FALSE), not null
#  shown_with_parent_only     :boolean          default(FALSE), not null
#  slug                       :string           not null
#  version                    :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  map_parent_id              :uuid
#  parent_id                  :uuid
#  system_id                  :uuid
#
# Indexes
#
#  index_locations_on_map_parent_id          (map_parent_id)
#  index_locations_on_mission_template_refs  (mission_template_refs) USING gin
#  index_locations_on_name                   (name)
#  index_locations_on_parent_id              (parent_id)
#  index_locations_on_sc_key                 (sc_key) UNIQUE
#  index_locations_on_sc_refs                (sc_refs) USING gin
#  index_locations_on_slug                   (slug) UNIQUE
#  index_locations_on_system_id              (system_id)
#  index_locations_on_version                (version)
#
# Foreign Keys
#
#  fk_rails_...  (map_parent_id => locations.id) ON DELETE => nullify
#  fk_rails_...  (parent_id => locations.id) ON DELETE => nullify
#  fk_rails_...  (system_id => locations.id) ON DELETE => nullify
#
class Location < ApplicationRecord
  include SlugConcern
  include ScDataVersioned

  paginates_per 60

  KINDS = %w[
    system star planet moon city station outpost asteroid
    anomaly jump_point point_of_interest nav_point other
  ].freeze

  belongs_to :parent, class_name: "Location", optional: true, inverse_of: :children
  belongs_to :map_parent, class_name: "Location", optional: true
  belongs_to :system, class_name: "Location", optional: true

  has_many :children, class_name: "Location", foreign_key: :parent_id, inverse_of: :parent, dependent: :nullify

  has_many :terminals, dependent: :nullify
  has_many :game_mission_locations, dependent: :destroy
  has_many :game_missions, -> { distinct }, through: :game_mission_locations

  has_many :builds, class_name: "LocationBuild", dependent: :destroy

  has_one :build, -> { current(::Location.served_source) },
    class_name: "LocationBuild", inverse_of: :location

  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "LocationBuild", inverse_of: :location

  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: LocationBuild.current(served_source(source)).select(:location_id))
    else
      all
    end
  }

  # Set by the loader, which knows every name in the tree before it writes the
  # first row. Asking the table instead would make the slug depend on load
  # order: the first "Outpost 54" in would take the bare name. Not an attribute,
  # so setting it does not read as a change to the row.
  attr_accessor :name_shared

  # Curated, where everything else is loaded: no game file carries a picture
  # of a planet.
  has_one_attached :image

  before_save :update_slugs

  validates :sc_key, presence: true, uniqueness: true
  validates :image, no_vector_image: true
  validates :color, format: {with: /\A#\h{6}\z/}, allow_blank: true

  DEFAULT_SORTING_PARAMS = ["name asc"]

  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "kind asc", "kind desc",
    "createdAt asc", "createdAt desc"
  ]

  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN location_builds AS location_facts
        ON location_facts.location_id = locations.id
       AND location_facts.environment = ?
       AND location_facts.version = ?
    SQL
  end

  def self.all_facts_join(source)
    facts = LocationBuild::FILTERABLE.map { |fact| "COALESCE(b.#{fact}, p.#{fact}) AS #{fact}" }.join(", ")

    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT p.id AS location_id, #{facts}
        FROM locations p
        LEFT JOIN (
          SELECT DISTINCT ON (location_id) *
          FROM location_builds
          WHERE environment = ?
          ORDER BY location_id, (version = ?) DESC, created_at DESC
        ) b ON b.location_id = p.id
      ) AS location_facts ON location_facts.location_id = locations.id
    SQL
  end

  def self.fact_sql(fact)
    Arel.sql("location_facts.#{fact}")
  end

  LocationBuild::FILTERABLE.each do |fact|
    ransacker(fact) { Location.fact_sql(fact) }
  end

  def self.readable_builds(source = ::ScData::Source.current, current_only: true)
    return LocationBuild.current(source) if ActiveModel::Type::Boolean.new.cast(current_only)

    LocationBuild.from(
      LocationBuild.for_source(source)
        .select("DISTINCT ON (location_id) location_builds.*")
        .order(Arel.sql(sanitize_sql_array(["location_id, (version = ?) DESC, created_at DESC", source.version]))),
      :location_builds
    )
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id name parent_id sc_key slug system_id updated_at version] + LocationBuild::FILTERABLE.map(&:to_s)
  end

  def self.ransackable_associations(auth_object = nil)
    %w[builds parent system]
  end

  def self.ransackable_scopes(auth_object = nil)
    %i[current_version]
  end

  def facts
    build || last_build
  end

  def retired?
    build.blank?
  end

  LocationBuild::READ_THROUGH.each do |fact|
    define_method(fact) { facts.nil? ? super() : facts.public_send(fact) }
  end

  # Up to the system, nearest first.
  def ancestors
    chain = []
    current = parent

    while current && chain.exclude?(current)
      chain << current
      current = current.parent
    end

    chain
  end

  # A place whose name another place carries too is told apart by its parent:
  # "outpost-54-aberdeen". Two copies under one parent still need the key --
  # Outpost 54's Reyes and Sloane facilities both sit on Aberdeen.
  #
  # Off the row's own column rather than `name`: that reads through to the
  # build, which a load writes after the row, so a rename would reach the slug
  # one load late.
  # How a star of each spectral class looks, for the glow it is drawn with. The
  # hot classes are kept off pure blue-white so they still read as a light on
  # a dark page.
  STELLAR_COLORS = {
    "O" => "#a9c1ff", "B" => "#bcd0ff", "A" => "#dfe7ff", "F" => "#fff3d6",
    "G" => "#ffe08a", "K" => "#ffb066", "M" => "#ff8352"
  }.freeze

  # The class the game's description names: "A class-G main sequence star",
  # "A K-type main sequence flare star". Nyx's star has no description.
  def stellar_class
    return unless kind == "star"

    text = description.to_s
    (text[/\bclass-([OBAFGKM])\b/i, 1] || text[/\b([OBAFGKM])-type\b/, 1])&.upcase
  end

  # The colour a place is drawn in: the one set in admin, else a star's from
  # its class.
  def drawn_color
    color.presence || STELLAR_COLORS[stellar_class]
  end

  # The game names Pyro's star a "K-type main sequence flare star", and that is
  # all it says about one being unstable.
  def flare_star?
    kind == "star" && description.to_s.match?(/\bflare star\b/i)
  end

  private def update_slugs
    own_name = self[:name]
    base = self.class.slug_for(own_name)
    return self.slug = nil if base.blank?

    candidates = [
      (base unless name_shared?(own_name)),
      self.class.slug_for([own_name, parent&.[](:name)].compact.join(" ")),
      "#{base}-#{self.class.slug_for(sc_key.tr("_", "-"))}"
    ].compact.uniq
    # A place keeps the URL it has while its name does: a namesake arriving
    # in a later build -- or in a ptu tree, which shares these rows -- takes
    # the longer slug instead of renaming the incumbent.
    return if persisted? && slug.present? && (slug == base || slug.start_with?("#{base}-"))

    self.slug = candidates.find { |candidate| !self.class.where(slug: candidate).where.not(id:).exists? } || candidates.last
  end

  private def name_shared?(own_name)
    return name_shared unless name_shared.nil?

    self.class.where(name: own_name).where.not(id:).exists?
  end
end
