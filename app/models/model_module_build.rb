# frozen_string_literal: true

# What one build of the game says about a model module.
#
# The fifth catalogue, and the last to get one. Two fields is thin next to
# `ModelBuild`'s twenty-eight, and they are not the reason this exists: a module
# row is created by `ModulesImporter` or by an admin, never by the loader, and it
# is shared by every source. Without a row here there is no way to ask whether a
# build describes a module at all -- so a module only the PTU build ships is
# offered under live as well, with an empty loadout, because its slots carry
# `HardpointBuild` rows for ptu and not for live.
# == Schema Information
#
# Table name: model_module_builds
#
#  id              :uuid             not null, primary key
#  cargo_holds     :string
#  description     :text
#  environment     :string           not null
#  version         :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_module_id :uuid             not null
#
# Indexes
#
#  index_model_module_builds_on_environment_and_version  (environment,version)
#  index_model_module_builds_on_model_module_id          (model_module_id)
#  index_model_module_builds_on_module_and_build         (model_module_id,environment,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (model_module_id => model_modules.id) ON DELETE => cascade
#
class ModelModuleBuild < ApplicationRecord
  belongs_to :model_module

  # Everything a build says, as opposed to what identifies or curates the
  # module. `name`, `slug`, the prices, `manufacturer_id`, `active` and `hidden`
  # are Fleetyards' own and stay on the row.
  #
  # `production_status` stays on the row too, and not because it belongs there:
  # the loader hardcodes it to "flight-ready" while the admin API also permits
  # it, so it is a load-versus-curation conflict that predates this table and
  # wants deciding on its own rather than being quietly settled here.
  FACTS = %i[description cargo_holds].freeze

  # The facts `ModelModule` reads through its build. `cargo_holds` is held back
  # for the same kind of reason `ComponentBuild` holds back `manufacturer_id` and
  # `hidden`: a `before_save` reads it. `set_cargo_from_hardpoints` derives
  # `cargo` from `cargo_holds`, so a reader that answered from the build would
  # hand the callback the *previous* build's value on the second load and store a
  # capacity the module does not have. The build row still records it, for a
  # per-build comparison; nothing reads it through.
  READ_THROUGH = (FACTS - %i[cargo_holds]).freeze

  # The same serialization the module declares, so a build reads back the
  # structure the column encodes rather than a raw YAML string.
  serialize :cargo_holds, coder: YAML

  validates :environment, presence: true
  validates :version, presence: true
  validates :model_module_id, uniqueness: {scope: [:environment, :version]}

  # The facts a build row holds, read off a module.
  def self.facts_from(model_module)
    FACTS.index_with { |fact| model_module.public_send(fact) }
  end

  # Every build this environment still has.
  scope :for_source, ->(source = ::ScData::Source.current) {
    where(environment: source.environment)
  }

  # The one build the environment is on.
  scope :current, ->(source = ::ScData::Source.current) {
    where(environment: source.environment, version: source.version)
  }

  # The versions worth keeping for one environment, ordered by when they first
  # appeared.
  def self.retained_versions(environment, keep: ::ScData::Source.builds_retained(environment))
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
