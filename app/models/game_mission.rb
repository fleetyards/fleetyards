# frozen_string_literal: true

# A contract the game can offer: who wants it done, what standing it takes to be
# offered it, how hard it is, and what finishing it pays.
#
# One row per contract rather than per title. The export models every variant as
# its own record -- "Salvager Needed (Med. Supply of RMC)" is four contracts, one
# per system -- and collapsing them would need an identity the game does not
# give, while losing the system and the standing band that tell the four apart.
# == Schema Information
#
# Table name: game_missions
#
#  id                          :uuid             not null, primary key
#  alignment                   :string
#  blueprint_pool_refs         :text             default([]), not null, is an Array
#  debug_name                  :string
#  description                 :text
#  difficulty_game_knowledge   :integer
#  difficulty_mechanical_skill :integer
#  difficulty_mental_load      :integer
#  difficulty_profile          :string
#  difficulty_risk_of_loss     :integer
#  generator_key               :string
#  kind                        :string
#  max_standing                :string
#  min_standing                :string
#  name                        :string
#  org_key                     :string
#  org_lawful                  :boolean
#  org_name                    :string
#  org_ref                     :string
#  released                    :boolean          default(TRUE), not null
#  reward_kinds                :text             default([]), not null, is an Array
#  sc_key                      :string           not null
#  sc_ref                      :string           not null
#  slug                        :string           not null
#  version                     :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_game_missions_on_org_name  (org_name)
#  index_game_missions_on_sc_key    (sc_key) UNIQUE
#  index_game_missions_on_sc_ref    (sc_ref) UNIQUE
#  index_game_missions_on_slug      (slug) UNIQUE
#  index_game_missions_on_version   (version)
#
class GameMission < ApplicationRecord
  include SlugConcern
  include ScDataVersioned

  paginates_per 60

  # What each build of the game says about this mission.
  has_many :builds, class_name: "GameMissionBuild", dependent: :destroy

  # The build we are being served from, which is the configured one unless its
  # load has not run yet. Resolved through `served_source` for the reason
  # `Blueprint#build` documents: `current` on its own has to keep meaning
  # exactly the configured build, because `ScData::CheckJob` asks it whether the
  # new build has landed.
  has_one :build, -> { current(::GameMission.served_source) },
    class_name: "GameMissionBuild", inverse_of: :game_mission

  # The newest build of this environment that still describes the mission, which
  # is what one the export dropped falls back to.
  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "GameMissionBuild", inverse_of: :game_mission

  # Whether the build we are on describes this mission, rather than whether the
  # version string on the row still matches. An exists check rather than a join,
  # so nothing fans out.
  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: GameMissionBuild.current(served_source(source)).select(:game_mission_id))
    else
      all
    end
  }

  # Missions the game is actually offering. The catalogue's own predicate, and
  # the one the list and the detail page both have to apply -- a page reachable
  # from nowhere is worse than a row, and a row linking to a 404 is worse still.
  scope :released, ->(source = ::ScData::Source.current, current_only: true) {
    where(id: readable_builds(source, current_only:).where(released: true).select(:game_mission_id))
  }

  # Missions an org offers, in the build we are on. Through the build, like
  # everything else: the columns on the row carry whatever the last source to
  # load wrote, so filtering them would answer a ptu request with live's.
  scope :from_org, ->(org_name, source = ::ScData::Source.current, current_only: true) {
    where(id: readable_builds(source, current_only:).where(org_name:).select(:game_mission_id))
  }

  # Missions that pay something of a given kind. An array containment check, so
  # it lands on the GIN index rather than an exists check per row.
  scope :rewarding, ->(kind, source = ::ScData::Source.current, current_only: true) {
    where(
      id: readable_builds(source, current_only:)
        .where("reward_kinds && ARRAY[?]::text[]", Array.wrap(kind))
        .select(:game_mission_id)
    )
  }

  # Missions that hand out a blueprint. Asked with the pool refs the build
  # carries rather than by joining `blueprint_sources`, which holds its own copy
  # of the mission and would match on the title.
  scope :dropping_pool, ->(pool_sc_ref, source = ::ScData::Source.current, current_only: true) {
    where(
      id: readable_builds(source, current_only:)
        .where("blueprint_pool_refs && ARRAY[?]::text[]", Array.wrap(pool_sc_ref))
        .select(:game_mission_id)
    )
  }

  before_save :update_slugs

  validates :sc_ref, presence: true, uniqueness: true
  validates :sc_key, presence: true, uniqueness: true

  DEFAULT_SORTING_PARAMS = ["name asc"]

  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "orgName asc", "orgName desc",
    "createdAt asc", "createdAt desc"
  ]

  # The build a filter resolves against, joined as `game_mission_facts`. Two
  # shapes behind one alias, so a ransacker stays a single static expression
  # either way -- see `Blueprint.current_facts_join` for why.
  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN game_mission_builds AS game_mission_facts
        ON game_mission_facts.game_mission_id = game_missions.id
       AND game_mission_facts.environment = ?
       AND game_mission_facts.version = ?
    SQL
  end

  # Everything: rows only an older build describes, and rows no load ever did.
  def self.all_facts_join(source)
    facts = GameMissionBuild::FILTERABLE.map { |fact| "COALESCE(b.#{fact}, p.#{fact}) AS #{fact}" }.join(", ")

    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT p.id AS game_mission_id, #{facts}
        FROM game_missions p
        LEFT JOIN (
          SELECT DISTINCT ON (game_mission_id) *
          FROM game_mission_builds
          WHERE environment = ?
          ORDER BY game_mission_id, (version = ?) DESC, created_at DESC
        ) b ON b.game_mission_id = p.id
      ) AS game_mission_facts ON game_mission_facts.game_mission_id = game_missions.id
    SQL
  end

  # One fact, off whichever build the join supplied. Referencing the alias
  # without `with_facts` raises rather than returning the wrong rows.
  def self.fact_sql(fact)
    Arel.sql("game_mission_facts.#{fact}")
  end

  GameMissionBuild::FILTERABLE.each do |fact|
    ransacker(fact) { GameMission.fact_sql(fact) }
  end

  # The build a read resolves through, for one source: the build we are on where
  # there is one, and the newest older build otherwise. Mirrors exactly what
  # `all_facts_join` picks, so a filter and the row it renders agree about which
  # build they are talking about.
  def self.readable_builds(source = ::ScData::Source.current, current_only: true)
    return GameMissionBuild.current(source) if ActiveModel::Type::Boolean.new.cast(current_only)

    GameMissionBuild.from(
      GameMissionBuild.for_source(source)
        .select("DISTINCT ON (game_mission_id) game_mission_builds.*")
        .order(Arel.sql(sanitize_sql_array(["game_mission_id, (version = ?) DESC, created_at DESC", source.version]))),
      :game_mission_builds
    )
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id id_value name sc_key slug updated_at version] + GameMissionBuild::FILTERABLE.map(&:to_s)
  end

  def self.ransackable_associations(auth_object = nil)
    %w[builds]
  end

  # `released` is deliberately not here. Ransack skips a scope given a false
  # value, so `released=false` would silently return the whole catalogue rather
  # than the missions the build is not offering -- it is applied by hand.
  def self.ransackable_scopes(auth_object = nil)
    %i[current_version]
  end

  # What the reader is served: the build we are on, falling back to the newest
  # older one so a mission the export dropped still describes itself.
  def facts
    build || last_build
  end

  def retired?
    build.blank?
  end

  # Every fact is a column here as well, so a mission no build describes still
  # answers off the row rather than raising.
  GameMissionBuild::READ_THROUGH.each do |fact|
    define_method(fact) { facts.nil? ? super() : facts.public_send(fact) }
  end

  # The orgs that actually offer work in the build being read -- 29 of the 38
  # the export declares a reputation record for. Built from the loaded
  # catalogue rather than from the reputation tree, so an org a patch stops
  # giving work to stops being offered as a filter.
  #
  # Off `readable_builds` rather than off the row, for the reason the blueprint
  # filters are: the build a list is answered from is the *served* one, and a
  # caller reading the fallback build has to be offered what that build names.
  def self.org_filters(source = served_source, current_only: true)
    readable_builds(source, current_only:)
      .where.not(org_name: nil)
      .distinct
      .order(:org_name)
      .pluck(:org_name, :org_key)
      .map { |name, key| Filter.new(category: "org", label: name, value: key) }
  end

  # The bands missions are offered in, which is a small subset of the 380
  # standing records: a band nothing is offered in is not a question to ask.
  #
  # Ordered by name because the export states no rank order anywhere a parse can
  # read -- the records carry a display name and a debug name, and neither
  # sorts "Neutral" below "Elite Contractor".
  def self.standing_filters(source = served_source, current_only: true)
    readable_builds(source, current_only:)
      .where.not(min_standing: nil)
      .distinct
      .order(:min_standing)
      .pluck(:min_standing)
      .map { |standing| Filter.new(category: "standing", label: standing, value: standing) }
  end

  # From the constant rather than from a DISTINCT over the array column: all
  # four are always offerable, and a kind nothing currently pays is still a
  # question worth being able to ask.
  def self.reward_kind_filters
    GameMissionBuild::REWARD_KINDS.map do |kind|
      Filter.new(
        category: "reward_kind",
        label: I18n.t("filter.game_mission.reward_kind.items.#{kind}", default: kind.humanize),
        value: kind
      )
    end
  end

  private def update_slugs
    # From the key rather than the title, the way a blueprint's is. 2536
    # contracts share 836 titles between them -- every difficulty and system
    # variant repeats one -- and 902 of those titles carry a `~mission(...)`
    # span the game fills in at run time, which is not a URL.
    #
    # `parameterize` leaves an underscore alone and every key is written with
    # them, so they become the separator a URL reads with. 51 keys carry a dash
    # of their own already; swapping the underscores collides with none of them.
    generate_slug(sc_key.tr("_", "-"))
  end

  # The recipes this mission hands out, through the pools it names. The other
  # end of the link `blueprint_sources` already carries by ref.
  def blueprints(source = ::ScData::Source.current)
    return Blueprint.none if blueprint_pool_refs.blank?

    Blueprint.where(
      id: BlueprintBuild.current(source)
        .where(id: BlueprintSource.where(pool_sc_ref: blueprint_pool_refs).select(:blueprint_build_id))
        .select(:blueprint_id)
    )
  end
end
