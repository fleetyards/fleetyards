# frozen_string_literal: true

# An org a player earns standing with, and the ladders they climb there.
class Faction < ApplicationRecord
  include ScDataVersioned

  # The record's own element name, less the prefix and the alignment every key
  # repeats: `factionreputation_lawful_redwindlinehaul` is `redwindlinehaul`.
  KEY_PREFIX = /\Afactionreputation_(?:(?:un)?lawful_)?/

  has_many :builds, class_name: "FactionBuild", dependent: :destroy

  has_one :build, -> { current(::Faction.served_source) },
    class_name: "FactionBuild", inverse_of: :faction

  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "FactionBuild", inverse_of: :faction

  has_one_attached :logo

  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: FactionBuild.current(served_source(source)).select(:faction_id))
    else
      all
    end
  }

  before_validation :assign_slug

  validates :sc_ref, presence: true, uniqueness: true
  validates :sc_key, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  # The build a read resolves against, joined as `faction_facts`.
  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN faction_builds AS faction_facts
        ON faction_facts.faction_id = factions.id
       AND faction_facts.environment = ?
       AND faction_facts.version = ?
    SQL
  end

  # Everything: factions only an older build describes, and rows no load ever
  # did, which answer with the name on the row and nothing else.
  def self.all_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT p.id AS faction_id, COALESCE(b.name, p.name) AS name, b.focus AS focus
        FROM factions p
        LEFT JOIN (
          SELECT DISTINCT ON (faction_id) *
          FROM faction_builds
          WHERE environment = ?
          ORDER BY faction_id, (version = ?) DESC, created_at DESC
        ) b ON b.faction_id = p.id
      ) AS faction_facts ON faction_facts.faction_id = factions.id
    SQL
  end

  def self.fact_sql(fact)
    Arel.sql("faction_facts.#{fact}")
  end

  # Derived from the key alone so a mission can link to its faction from
  # `org_key` without a lookup per row.
  def self.slug_for_key(key)
    key.to_s.sub(KEY_PREFIX, "").tr("_", "-").presence
  end

  # Released, named missions per offering org, in the build being read.
  def self.mission_counts(source = ::GameMission.served_source)
    offered_builds(source).where.not(org_key: nil).group(:org_key).count
  end

  def self.offered_builds(source)
    ::GameMissionBuild.current(source)
      .where(released: true)
      .where(game_mission_id: ::GameMission.named(source).select(:id))
  end

  def facts
    build || last_build
  end

  (FactionBuild::FACTS - [:name]).each do |fact|
    define_method(fact) { facts&.public_send(fact) }
  end

  def name
    facts&.name || super
  end

  def ladders
    facts&.ladders.to_a
  end

  def mission_count(source = ::GameMission.served_source)
    self.class.offered_builds(source).where(org_key: sc_key).count
  end

  # What completing a mission for this faction adds to each ladder, keyed by
  # ladder. Gains only: a loss is the price of work for someone else, not a way
  # up this ladder.
  def ladder_awards(source = ::GameMission.served_source)
    ::GameMissionReward
      .where(game_mission_build_id: self.class.offered_builds(source).select(:id))
      .where(kind: "reputation", org_key: sc_key, outcome: "completed")
      .where("amount > 0")
      .where.not(ladder_key: nil)
      .group(:ladder_key)
      .pluck(
        :ladder_key,
        Arel.sql("COUNT(DISTINCT game_mission_build_id)"),
        Arel.sql("MIN(amount)"),
        Arel.sql("MAX(amount)")
      )
      .to_h { |key, missions, min, max| [key, {missions:, min:, max:}] }
  end

  private def assign_slug
    self.slug = self.class.slug_for_key(sc_key)
  end
end
